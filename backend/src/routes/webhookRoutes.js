const express = require('express');

const {
    handlePaymentWebhook
} = require('../controllers/webhookController');

const router = express.Router();

router.post('/', handlePaymentWebhook);

module.exports = router;