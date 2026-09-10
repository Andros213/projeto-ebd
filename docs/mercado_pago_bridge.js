(function () {
  let paymentBrickController = null;
  let mp = null;

  window.MercadoPagoBridge = {
    initialize: function (publicKey) {
      if (!publicKey) {
        return Promise.reject(
          new Error("Chave pública do Mercado Pago não informada.")
        );
      }

      if (typeof MercadoPago === "undefined") {
        return Promise.reject(
          new Error("SDK do Mercado Pago não foi carregado.")
        );
      }

      try {
        mp = new MercadoPago(publicKey, {
          locale: "pt-BR",
        });

        return Promise.resolve(true);
      } catch (error) {
        return Promise.reject(error);
      }
    },

    renderPaymentBrick: async function (
      containerId,
      amount,
      preferenceId,
      onSubmit,
      onReady,
      onError
    ) {
      if (!mp) {
        throw new Error(
          "Mercado Pago ainda não foi inicializado."
        );
      }

      const container =
        document.getElementById(containerId);

      if (!container) {
        throw new Error(
          "Container do Payment Brick não encontrado."
        );
      }

      if (paymentBrickController) {
        try {
          await paymentBrickController.unmount();
        } catch (_) {}

        paymentBrickController = null;
      }

      const bricksBuilder = mp.bricks();

      const settings = {
        initialization: {
          amount: Number(amount),
          preferenceId: String(preferenceId),
        },

        customization: {
          paymentMethods: {
            creditCard: "all",
            debitCard: "all",
            prepaidCard: "all",
            ticket: "all",
            bankTransfer: "all",
            mercadoPago: "all",
          },
        },

        callbacks: {
          onReady: function () {
            if (typeof onReady === "function") {
              onReady();
            }
          },

          onSubmit: async function ({
            selectedPaymentMethod,
            formData,
          }) {
            try {
              if (typeof onSubmit !== "function") {
                throw new Error(
                  "Callback de pagamento não configurado."
                );
              }

              await onSubmit(
                JSON.stringify(formData)
              );
            } catch (error) {
              if (typeof onError === "function") {
                onError(error);
              }

              throw error;
            }
          },

          onError: function (error) {
            console.error(
              "Erro no Payment Brick:",
              error
            );

            if (typeof onError === "function") {
              onError(
                JSON.stringify(error)
              );
            }
          },
        },
      };

      paymentBrickController =
        await bricksBuilder.create(
          "payment",
          containerId,
          settings
        );

      return true;
    },

    destroyPaymentBrick: function () {
      if (paymentBrickController) {
        paymentBrickController.unmount();
        paymentBrickController = null;
      }
    },
  };
})();