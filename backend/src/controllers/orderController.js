const orderService = require('../services/orderService');

async function createOrder(req, res) {
    try {
        const userId = req.user.userId;

        const order = await orderService.createOrder(userId);

        return res.status(201).json({
            success: true,
            message: 'Pedido criado com sucesso',
            order
        });

    } catch (error) {
        console.error('Erro ao criar pedido:', error);

        return res.status(400).json({
            success: false,
            message: error.message
        });
    }
}

async function listMyOrders(req, res) {
    try {
        const userId = req.user.userId;

        const orders = await orderService.listMyOrders(userId);

        return res.json({
            success: true,
            orders
        });

    } catch (error) {
        console.error('Erro ao listar meus pedidos:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao listar pedidos'
        });
    }
}

async function getMyOrderById(req, res) {
    try {
        const userId = req.user.userId;
        const orderId = Number(req.params.id);

        if (!Number.isInteger(orderId) || orderId <= 0) {
            return res.status(400).json({
                success: false,
                message: 'ID do pedido inválido'
            });
        }

        const order = await orderService.getMyOrderById(
            orderId,
            userId
        );

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Pedido não encontrado'
            });
        }

        return res.json({
            success: true,
            order
        });

    } catch (error) {
        console.error('Erro ao buscar meu pedido:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao buscar pedido'
        });
    }
}

module.exports = {
    createOrder,
    listMyOrders,
    getMyOrderById
};
