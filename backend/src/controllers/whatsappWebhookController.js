const crypto = require('crypto');


// ======================================================
// VERIFICAÇÃO DO WEBHOOK DA META
// ======================================================

function verifyWhatsAppWebhook(req, res) {
    const mode =
        req.query['hub.mode'];

    const token =
        req.query['hub.verify_token'];

    const challenge =
        req.query['hub.challenge'];


    const expectedToken =
        process.env.WHATSAPP_WEBHOOK_VERIFY_TOKEN;


    if (!expectedToken) {
        console.error(
            'WHATSAPP_WEBHOOK_VERIFY_TOKEN não configurado'
        );

        return res.sendStatus(500);
    }


    if (
        mode === 'subscribe' &&
        token === expectedToken
    ) {
        console.log(
            'Webhook WhatsApp verificado com sucesso'
        );

        return res
            .status(200)
            .send(challenge);
    }


    console.warn(
        'Falha na verificação do Webhook WhatsApp'
    );

    return res.sendStatus(403);
}


// ======================================================
// RECEBER EVENTOS DO WHATSAPP
// ======================================================

async function handleWhatsAppWebhook(req, res) {
    try {

        console.log(
            'Webhook WhatsApp recebido:'
        );

        console.log(
            JSON.stringify(
                req.body,
                null,
                2
            )
        );


        /*
         * A Meta espera uma resposta rápida.
         * O processamento das notificações será
         * implementado nas próximas etapas.
         */

        return res.sendStatus(200);

    } catch (error) {

        console.error(
            'Erro no Webhook WhatsApp:',
            error
        );

        return res.sendStatus(500);
    }
}


module.exports = {
    verifyWhatsAppWebhook,
    handleWhatsAppWebhook
};