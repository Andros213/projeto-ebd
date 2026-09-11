(function () {
  let paymentBrickController = null;
  let mp = null;

  function waitForContainer(containerId, timeout = 10000) {
    return new Promise((resolve, reject) => {
      const start = Date.now();

      function check() {
        const container = document.getElementById(containerId);

        if (container) {
          resolve(container);
          return;
        }

        if (Date.now() - start >= timeout) {
          reject(
            new Error(
              "Container do Payment Brick não encontrado."
            )
          );
          return;
        }

        setTimeout(check, 100);
      }

      check();
    });
  }

  window.MercadoPagoBridge = {
    initialize: function (publicKey) {
      if (!publicKey) {
        return Promise.reject(
          new Error(
            "Chave pública do Mercado Pago não informada."
          )
        );
      }

      if (typeof MercadoPago === "undefined") {
        return Promise.reject(
          new Error(
            "SDK do Mercado Pago não foi carregado."
          )
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

      const container = await waitForContainer(
        containerId
      );

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

          onSubmit: function ({
            selectedPaymentMethod,
            formData,
          }) {
            if (typeof onSubmit !== "function") {
              const error = new Error(
                "Callback de pagamento não configurado."
              );

              if (typeof onError === "function") {
                onError(error);
              }

              return Promise.reject(error);
            }

            try {
              console.log(
                "Payment Brick enviando pagamento:",
                selectedPaymentMethod
              );

              const result = onSubmit(
                JSON.stringify(formData)
              );

              // Garante que o Payment Brick sempre receba
              // uma Promise como retorno do onSubmit.
              return Promise.resolve(result).catch(
                function (error) {
                  console.error(
                    "Erro ao processar pagamento:",
                    error
                  );

                  if (typeof onError === "function") {
                    onError(error);
                  }

                  throw error;
                }
              );
            } catch (error) {
              console.error(
                "Erro ao iniciar processamento:",
                error
              );

              if (typeof onError === "function") {
                onError(error);
              }

              return Promise.reject(error);
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