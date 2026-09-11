const crypto = require('crypto');

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
// CRIAR PAGAMENTO PELO PAYMENT BRICK
// ======================================================

async function createPayment({
    order,
    paymentData
}) {

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

    if (!paymentData) {
        throw new Error(
            'Dados do pagamento não informados'
        );
    }


    // --------------------------------------------------
    // DADOS RECEBIDOS DO PAYMENT BRICK
    // --------------------------------------------------

    const {
        token,
        transaction_amount,
        installments,
        payment_method_id,
        issuer_id,
        payer
    } = paymentData;


    // --------------------------------------------------
    // MÉTODO DE PAGAMENTO
    // --------------------------------------------------

    if (
        !payment_method_id ||
        String(payment_method_id).trim().length === 0
    ) {
        throw new Error(
            'Método de pagamento não informado'
        );
    }

    const paymentMethodId =
        String(payment_method_id)
            .trim()
            .toLowerCase();


    // --------------------------------------------------
    // PAGADOR
    // --------------------------------------------------

    if (
        !payer ||
        !payer.email ||
        String(payer.email).trim().length === 0
    ) {
        throw new Error(
            'E-mail do pagador não informado'
        );
    }


    // --------------------------------------------------
    // VALOR
    // --------------------------------------------------

    const amount =
        Number(transaction_amount);

    if (
        !Number.isFinite(amount) ||
        amount <= 0
    ) {
        throw new Error(
            'Valor do pagamento inválido'
        );
    }


    const orderTotal =
        Number(order.total);


    // --------------------------------------------------
    // VALIDAR VALOR
    // --------------------------------------------------

    if (
        !Number.isFinite(orderTotal) ||
        Math.abs(amount - orderTotal) > 0.01
    ) {
        throw new Error(
            'O valor do pagamento não corresponde ao valor do pedido'
        );
    }


    // --------------------------------------------------
    // CLIENTE MERCADO PAGO
    // --------------------------------------------------

    const client =
        getMercadoPagoClient();

    const payment =
        new Payment(client);


    // --------------------------------------------------
    // ID DE IDEMPOTÊNCIA
    // --------------------------------------------------

    const idempotencyKey =
        crypto.randomUUID();


    // --------------------------------------------------
    // PAGADOR
    // --------------------------------------------------

    const payerBody = {

        email:
            String(
                payer.email
            ).trim()

    };


    // --------------------------------------------------
    // IDENTIFICAÇÃO DO PAGADOR
    // --------------------------------------------------

    if (
        payer.identification &&
        payer.identification.type &&
        payer.identification.number
    ) {

        payerBody.identification = {

            type:
                String(
                    payer.identification.type
                ),

            number:
                String(
                    payer.identification.number
                )

        };

    }


    // --------------------------------------------------
    // DADOS BÁSICOS DO PAGAMENTO
    // --------------------------------------------------

    const body = {

        transaction_amount:
            Number(
                amount.toFixed(2)
            ),

        description:
            `Pedido EBD #${order.id}`,

        payment_method_id:
            paymentMethodId,

        payer:
            payerBody,

        external_reference:
            String(
                order.id
            )

    };


    // --------------------------------------------------
    // TOKEN
    //
    // Necessário para cartão.
    // Não é enviado para Pix/Boleto.
    // --------------------------------------------------

    if (
        token &&
        String(token).trim().length > 0
    ) {

        body.token =
            String(
                token
            );

    }


    // --------------------------------------------------
    // PARCELAS
    //
    // Usadas quando o Brick enviar esse campo.
    // Pix não precisa de parcelas.
    // --------------------------------------------------

    if (
        installments !== undefined &&
        installments !== null &&
        String(installments).trim().length > 0
    ) {

        const installmentsNumber =
            Number(installments);

        if (
            Number.isInteger(installmentsNumber) &&
            installmentsNumber > 0
        ) {

            body.installments =
                installmentsNumber;

        }

    }


    // --------------------------------------------------
    // ISSUER
    // --------------------------------------------------

    if (
        issuer_id !== undefined &&
        issuer_id !== null &&
        String(issuer_id).trim().length > 0
    ) {

        const issuerNumber =
            Number(issuer_id);

        if (
            Number.isFinite(issuerNumber)
        ) {

            body.issuer_id =
                issuerNumber;

        }

    }


    // --------------------------------------------------
    // VALIDAÇÃO ESPECÍFICA PARA CARTÃO
    // --------------------------------------------------

    const isCardPayment =
        paymentMethodId.includes('visa') ||
        paymentMethodId.includes('master') ||
        paymentMethodId.includes('elo') ||
        paymentMethodId.includes('hipercard') ||
        paymentMethodId.includes('amex') ||
        paymentMethodId.includes('diners') ||
        paymentMethodId.includes('card');


    if (
        isCardPayment &&
        !body.token
    ) {

        throw new Error(
            'Token do cartão não informado'
        );

    }


    // --------------------------------------------------
    // LOG
    // --------------------------------------------------

    console.log(
        'Criando pagamento pelo Payment Brick:',
        {
            orderId:
                order.id,

            amount,

            paymentMethodId,

            hasToken:
                Boolean(body.token)
        }
    );


    // --------------------------------------------------
    // CRIAR PAGAMENTO
    // --------------------------------------------------

    const result =
        await payment.create({

            body,

            requestOptions: {

                idempotencyKey

            }

        });


    // --------------------------------------------------
    // RETORNO
    // --------------------------------------------------

    return result;
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

    createPayment,

    getPayment

};