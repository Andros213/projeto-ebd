const express = require('express');

const {
    verifyWhatsAppWebhook,
    handleWhatsAppWebhook
} = require('../controllers/whatsappWebhookController');


const router = express.Router();


router.get(
    '/',
    verifyWhatsAppWebhook
);


router.post(
    '/',
    handleWhatsAppWebhook
);


module.exports = router;