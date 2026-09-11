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
            new Error("Container do Payment Brick não encontrado.")
          );
          return;
        }

        setTimeout(check, 100);
      }

      check();
    });
  }

  // ======================================================
  // DEVICE ID DO MERCADO PAGO
  // ======================================================

  function getDeviceSessionId() {
    try {
      if (
        typeof window.MP_DEVICE_SESSION_ID === "string" &&
        window.MP_DEVICE_SESSION_ID.trim().length > 0
      ) {
        return window.MP_DEVICE_SESSION_ID.trim();
      }
    } catch (_) {}

    return null;
  }

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
          advancedFraudPrevention: true,
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

      const container = await waitForContainer(containerId);

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
            console.log(
              "Payment Brick pronto."
            );

            if (typeof onReady === "function") {
              onReady();
            }
          },

          onSubmit: function ({
            selectedPaymentMethod,
            formData,
          }) {
            console.log(
              "Payment Brick enviando pagamento:",
              selectedPaymentMethod
            );

            if (typeof onSubmit !== "function") {
              const error = new Error(
                "Callback de pagamento não configurado."
              );

              if (typeof onError === "function") {
                onError(error);
              }

              return Promise.resolve();
            }

            try {
              // --------------------------------------------------
              // ADICIONAR DEVICE ID AOS DADOS ENVIADOS AO FLUTTER
              // --------------------------------------------------

              const deviceSessionId =
                getDeviceSessionId();

              const paymentData = {
                ...formData,
              };

              if (deviceSessionId) {
                paymentData.device_session_id =
                  deviceSessionId;

                console.log(
                  "Device ID do Mercado Pago disponível:",
                  true
                );
              } else {
                console.warn(
                  "Device ID do Mercado Pago não disponível."
                );
              }

              const callbackResult =
                onSubmit(
                  JSON.stringify(paymentData)
                );

              return Promise.resolve(callbackResult)
                .then(function (result) {
                  console.log(
                    "Flutter finalizou o processamento do pagamento."
                  );

                  return result;
                })
                .catch(function (error) {
                  console.error(
                    "Erro retornado pelo Flutter:",
                    error
                  );

                  if (typeof onError === "function") {
                    onError(error);
                  }

                  return null;
                });

            } catch (error) {
              console.error(
                "Erro síncrono ao chamar Flutter:",
                error
              );

              if (typeof onError === "function") {
                onError(error);
              }

              return Promise.resolve();
            }
          },

          onError: function (error) {
            console.error(
              "Erro no Payment Brick:",
              error
            );

            if (typeof onError === "function") {
              try {
                onError(JSON.stringify(error));
              } catch (_) {
                onError(String(error));
              }
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
        try {
          paymentBrickController.unmount();
        } catch (_) {}

        paymentBrickController = null;
      }
    },
  };
})();