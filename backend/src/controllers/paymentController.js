const mercadoPagoService =
    require('../services/mercadoPagoService');


// ======================================================
// CRIAR PREFERENCE — CHECKOUT PRO
// ======================================================

async function createPreference(req, res) {

    try {

        const userId =
            req.user.userId;

        const orderId =
            Number(req.params.orderId);


        if (
            !Number.isInteger(orderId) ||
            orderId <= 0
        ) {

            return res.status(400).json({

                success: false,

                message:
                    'ID do pedido inválido'

            });

        }


        const order =
            await mercadoPagoService.getOrderForUser(
                orderId,
                userId
            );


        if (!order) {

            return res.status(404).json({

                success: false,

                message:
                    'Pedido não encontrado'

            });

        }


        const preference =
            await mercadoPagoService.createPreference(
                order
            );


        return res.status(201).json({

            success: true,

            message:
                'Preferência de pagamento criada',

            preference

        });

    }

    catch (error) {

        console.error(
            'Erro ao criar preferência de pagamento:',
            error
        );


        return res.status(400).json({

            success: false,

            message:
                error.message

        });

    }

}


// ======================================================
// PROCESSAR PAGAMENTO — PAYMENT BRICK
// ======================================================

async function processPayment(req, res) {

    try {

        const userId =
            req.user.userId;

        const orderId =
            Number(req.params.orderId);


        // ------------------------------------------------
        // VALIDAR PEDIDO
        // ------------------------------------------------

        if (
            !Number.isInteger(orderId) ||
            orderId <= 0
        ) {

            return res.status(400).json({

                success: false,

                message:
                    'ID do pedido inválido'

            });

        }


        // ------------------------------------------------
        // BUSCAR PEDIDO DO USUÁRIO
        // ------------------------------------------------

        const order =
            await mercadoPagoService.getOrderForUser(
                orderId,
                userId
            );


        if (!order) {

            return res.status(404).json({

                success: false,

                message:
                    'Pedido não encontrado'

            });

        }


        // ------------------------------------------------
        // NÃO PERMITIR PAGAR PEDIDO JÁ CONFIRMADO
        // ------------------------------------------------

        if (
            order.status === 'confirmed'
        ) {

            return res.status(400).json({

                success: false,

                message:
                    'Este pedido já foi confirmado'

            });

        }


        // ------------------------------------------------
        // PROCESSAR PAGAMENTO
        // ------------------------------------------------

        const payment =
            await mercadoPagoService.createPayment({

                order,

                paymentData:
                    req.body

            });


        // ------------------------------------------------
        // RETORNO
        // ------------------------------------------------

        return res.status(201).json({

            success: true,

            message:
                'Pagamento processado',

            payment: {

                id:
                    payment.id,

                status:
                    payment.status,

                status_detail:
                    payment.status_detail,

                transaction_amount:
                    payment.transaction_amount,

                payment_method_id:
                    payment.payment_method_id,

                pix:
                    payment.point_of_interaction?.transaction_data
                        ? {

                            qr_code:
                                payment.point_of_interaction.transaction_data.qr_code || null,

                            qr_code_base64:
                                payment.point_of_interaction.transaction_data.qr_code_base64 || null,

                            ticket_url:
                                payment.point_of_interaction.transaction_data.ticket_url || null

                        }
                        : null

            }

        });

    }

    catch (error) {

        console.error(
            'Erro ao processar pagamento pelo Payment Brick:',
            error
        );


        return res.status(400).json({

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

    createPreference,

    processPayment

};