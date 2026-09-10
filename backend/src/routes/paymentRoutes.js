const express = require('express');

const {

    createPreference,

    processPayment

} = require('../controllers/paymentController');

const authMiddleware =
    require('../middleware/authMiddleware');

const router =
    express.Router();


// ======================================================
// AUTENTICAÇÃO
// ======================================================

router.use(
    authMiddleware
);


// ======================================================
// CHECKOUT PRO — ROTA ATUAL
// ======================================================

router.post(
    '/:orderId',
    createPreference
);


// ======================================================
// PAYMENT BRICK
// ======================================================

router.post(
    '/:orderId/process',
    processPayment
);


module.exports = router;