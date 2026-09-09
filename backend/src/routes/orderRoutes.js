const express = require('express');

const {
    createOrder,
    listMyOrders,
    getMyOrderById
} = require('../controllers/orderController');

const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

// Listar pedidos do usuário logado
router.get('/', listMyOrders);

// Ver detalhes de um pedido do usuário logado
router.get('/:id', getMyOrderById);

// Finalizar compra / criar pedido
router.post('/', createOrder);

module.exports = router;