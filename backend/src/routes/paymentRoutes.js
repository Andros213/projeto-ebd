const express = require('express');

const {
    createPreference
} = require('../controllers/paymentController');

const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.post('/:orderId', createPreference);

module.exports = router;