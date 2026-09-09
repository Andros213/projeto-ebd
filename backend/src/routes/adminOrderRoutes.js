const express = require('express');

const {
    listAllOrders,
    getOrderById,
    updateOrderStatus
} = require('../controllers/adminOrderController');

const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

const router = express.Router();

router.use(authMiddleware);
router.use(adminMiddleware);

// Listar todos os pedidos
router.get('/', listAllOrders);

// Ver detalhes de um pedido
router.get('/:id', getOrderById);

// Alterar status de um pedido
router.patch('/:id/status', updateOrderStatus);

module.exports = router;
