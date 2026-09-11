const {
    WebhookSignatureValidator,
    InvalidWebhookSignatureError
} = require('mercadopago');

const mercadoPagoService =
    require('../services/mercadoPagoService');

const paymentRepository =
    require('../repositories/paymentRepository');

const orderRepository =
    require('../repositories/orderRepository');


// ======================================================
// VALIDAR ASSINATURA DO WEBHOOK
// ======================================================

function validateWebhookSignature(req) {

    const secret =
        process.env.MERCADO_PAGO_WEBHOOK_SECRET;

    if (!secret) {

        throw new Error(
            'MERCADO_PAGO_WEBHOOK_SECRET não configurado'
        );

    }

    const xSignature =
        req.headers['x-signature'];

    const xRequestId =
        req.headers['x-request-id'];

    const dataId =
        req.query['data.id'] ||
        req.body?.data?.id ||
        '';

    if (
        !xSignature ||
        !xRequestId ||
        !dataId
    ) {

        return false;

    }

    try {

        WebhookSignatureValidator.validate({

            xSignature,

            xRequestId,

            dataId:
                String(dataId),

            secret

        });

        console.log(
            'Assinatura do webhook validada pelo SDK do Mercado Pago.'
        );

        return true;

    } catch (error) {

        if (
            error instanceof
            InvalidWebhookSignatureError
        ) {

            console.error(
                'Falha na validação da assinatura do webhook:',
                error.message
            );

            return false;

        }

        throw error;
    }
}


// ======================================================
// WEBHOOK DO MERCADO PAGO
// ======================================================

async function handlePaymentWebhook(req, res) {

    try {

        const type =
            req.query.type ||
            req.body?.type;


        // --------------------------------------------------
        // IGNORAR EVENTOS QUE NÃO SEJAM PAYMENT
        // --------------------------------------------------

        if (
            type !== 'payment'
        ) {

            return res.status(200).json({

                success: true,

                message:
                    'Evento ignorado'

            });

        }


        // --------------------------------------------------
        // VALIDAR ASSINATURA
        // --------------------------------------------------

        if (
            !validateWebhookSignature(req)
        ) {

            return res.status(401).json({

                success: false,

                message:
                    'Assinatura inválida'

            });

        }


        // --------------------------------------------------
        // PEGAR ID DO PAGAMENTO
        // --------------------------------------------------

        const paymentId =
            req.query['data.id'] ||
            req.body?.data?.id;


        if (!paymentId) {

            return res.status(400).json({

                success: false,

                message:
                    'ID do pagamento não informado'

            });

        }


        // --------------------------------------------------
        // CONSULTAR PAGAMENTO NO MERCADO PAGO
        // --------------------------------------------------

        const payment =
            await mercadoPagoService.getPayment(
                paymentId
            );


        // --------------------------------------------------
        // PEGAR PEDIDO PELA EXTERNAL REFERENCE
        // --------------------------------------------------

        const externalReference =
            payment.external_reference;


        const orderId =
            Number(
                externalReference
            );


        if (
            !Number.isInteger(orderId) ||
            orderId <= 0
        ) {

            throw new Error(
                'External reference do pagamento inválida'
            );

        }


        // --------------------------------------------------
        // CONFIRMAR QUE O PEDIDO EXISTE
        // --------------------------------------------------

        const order =
            await orderRepository.findOrderById(
                orderId
            );


        if (!order) {

            throw new Error(
                `Pedido ${orderId} não encontrado`
            );

        }


        // --------------------------------------------------
        // VALIDAR VALOR
        // --------------------------------------------------

        const paymentAmount =
            Number(
                payment.transaction_amount
            );


        const orderAmount =
            Number(
                order.total
            );


        if (
            !Number.isFinite(
                paymentAmount
            ) ||
            !Number.isFinite(
                orderAmount
            ) ||
            Math.abs(
                paymentAmount -
                orderAmount
            ) > 0.01
        ) {

            throw new Error(
                'Valor do pagamento diferente do valor do pedido'
            );

        }


        // --------------------------------------------------
        // SALVAR / ATUALIZAR PAGAMENTO
        // --------------------------------------------------

        const savedPayment =
            await paymentRepository.createPayment({

                orderId,

                providerPaymentId:
                    payment.id,

                status:
                    payment.status,

                amount:
                    paymentAmount,

                paymentMethod:
                    payment.payment_method_id ||
                    payment.payment_type_id ||
                    null,

                externalReference:
                    String(
                        payment.external_reference
                    )

            });


        console.log(
            'Pagamento processado:',
            {
                paymentId:
                    payment.id,

                orderId,

                status:
                    payment.status,

                statusDetail:
                    payment.status_detail,

                paymentMethodId:
                    payment.payment_method_id,

                paymentTypeId:
                    payment.payment_type_id,

                paymentRecordId:
                    savedPayment.id
            }
        );


        // ==================================================
        // PAGAMENTO APROVADO
        // ==================================================

        if (
            payment.status === 'approved'
        ) {

            const confirmedOrder =
                await orderRepository.confirmPaidOrder(
                    orderId
                );


            console.log(
                'Pagamento aprovado. Pedido confirmado, estoque atualizado e carrinho atualizado:',
                {
                    orderId,

                    status:
                        confirmedOrder?.status
                }
            );

        }


        // ==================================================
        // PAGAMENTO PENDENTE
        // ==================================================

        if (
            payment.status === 'pending'
        ) {

            console.log(
                'Pagamento pendente. Pedido permanece pendente:',
                {
                    orderId,

                    statusDetail:
                        payment.status_detail
                }
            );

        }


        // ==================================================
        // PAGAMENTO RECUSADO
        // ==================================================

        if (
            payment.status === 'rejected'
        ) {

            console.log(
                'Pagamento recusado. Detalhes do Mercado Pago:',
                {
                    orderId,

                    paymentId:
                        payment.id,

                    status:
                        payment.status,

                    statusDetail:
                        payment.status_detail,

                    paymentMethodId:
                        payment.payment_method_id,

                    paymentTypeId:
                        payment.payment_type_id
                }
            );

        }


        // ==================================================
        // PAGAMENTO CANCELADO
        // ==================================================

        if (
            payment.status === 'cancelled'
        ) {

            console.log(
                'Pagamento cancelado:',
                {
                    orderId,

                    statusDetail:
                        payment.status_detail
                }
            );

        }


        return res.status(200).json({

            success: true

        });

    } catch (error) {

        console.error(
            'Erro no webhook do Mercado Pago:',
            error
        );


        /*
         * Mantemos 200 durante esta etapa de testes
         * para evitar uma sequência de reenvios.
         */

        return res.status(200).json({

            success: false,

            message:
                error.message

        });

    }
}


// ======================================================
// EXPORT
// ======================================================

module.exports = {
    handlePaymentWebhook
};