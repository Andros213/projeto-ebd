const {
    MercadoPagoConfig,
    Preference,
    Payment
} = require('mercadopago');

const orderRepository =
    require('../repositories/orderRepository');


// ======================================================
// BUSCAR PEDIDO DO USUÁRIO
// ======================================================

async function getOrderForUser(orderId, userId) {

    if (
        !Number.isInteger(orderId) ||
        orderId <= 0
    ) {
        throw new Error(
            'ID do pedido inválido'
        );
    }

    if (!userId) {
        throw new Error(
            'Usuário não identificado'
        );
    }

    const order =
        await orderRepository.findOrderByIdForUser(
            orderId,
            userId
        );

    return order;
}


// ======================================================
// CLIENTE MERCADO PAGO
// ======================================================

function getMercadoPagoClient() {

    const accessToken =
        process.env.MERCADO_PAGO_ACCESS_TOKEN;

    if (!accessToken) {
        throw new Error(
            'MERCADO_PAGO_ACCESS_TOKEN não configurado'
        );
    }

    return new MercadoPagoConfig({
        accessToken
    });
}


// ======================================================
// CRIAR PREFERENCE
// ======================================================

async function createPreference(order) {

    if (!order) {
        throw new Error(
            'Pedido não encontrado'
        );
    }

    if (
        !order.items ||
        order.items.length === 0
    ) {
        throw new Error(
            'Pedido não possui itens'
        );
    }

    const client =
        getMercadoPagoClient();

    const preference =
        new Preference(client);


    // --------------------------------------------------
    // ITENS
    // --------------------------------------------------

    const items =
        order.items.map((item) => ({

            id:
                String(
                    item.product_id
                ),

            title:
                item.product_name,

            quantity:
                Number(
                    item.quantity
                ),

            currency_id:
                'BRL',

            unit_price:
                Number(
                    item.unit_price
                )

        }));


    // --------------------------------------------------
    // WEBHOOK
    // --------------------------------------------------

    const webhookUrl =
        process.env.MERCADO_PAGO_WEBHOOK_URL;

    if (!webhookUrl) {
        throw new Error(
            'MERCADO_PAGO_WEBHOOK_URL não configurado'
        );
    }


    console.log(
        'Webhook configurado para a Preference:',
        webhookUrl
    );


    // --------------------------------------------------
    // CRIAR PREFERENCE
    // --------------------------------------------------

    const result =
        await preference.create({

            body: {

                items,

                external_reference:
                    String(
                        order.id
                    ),

                notification_url:
                    webhookUrl

            }

        });


    // --------------------------------------------------
    // RETORNO
    // --------------------------------------------------

    return {

        id:
            result.id,

        initPoint:
            result.init_point ||
            null,

        sandboxInitPoint:
            result.sandbox_init_point ||
            null

    };
}


// ======================================================
// BUSCAR PAGAMENTO
// ======================================================

async function getPayment(paymentId) {

    if (
        paymentId === null ||
        paymentId === undefined ||
        String(paymentId).trim().length === 0
    ) {
        throw new Error(
            'ID do pagamento não informado'
        );
    }

    const client =
        getMercadoPagoClient();

    const payment =
        new Payment(client);

    return await payment.get({

        id:
            String(
                paymentId
            )

    });
}


// ======================================================
// EXPORT
// ======================================================

module.exports = {

    getOrderForUser,

    createPreference,

    getPayment

};