const orderService = require('../services/orderService');

async function listAllOrders(req, res) {
    try {
        const orders = await orderService.listAllOrders();

        return res.json({
            success: true,
            orders
        });

    } catch (error) {
        console.error('Erro ao listar pedidos:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao listar pedidos'
        });
    }
}

async function getOrderById(req, res) {
    try {
        const orderId = Number(req.params.id);

        if (!Number.isInteger(orderId) || orderId <= 0) {
            return res.status(400).json({
                success: false,
                message: 'ID do pedido inválido'
            });
        }

        const order = await orderService.getOrderById(orderId);

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
        console.error('Erro ao buscar pedido:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao buscar pedido'
        });
    }
}

async function updateOrderStatus(req, res) {
    try {
        const orderId = Number(req.params.id);
        const { status } = req.body;

        if (!Number.isInteger(orderId) || orderId <= 0) {
            return res.status(400).json({
                success: false,
                message: 'ID do pedido inválido'
            });
        }

        if (!status) {
            return res.status(400).json({
                success: false,
                message: 'O campo status é obrigatório'
            });
        }

        const order = await orderService.changeOrderStatus(
            orderId,
            status
        );

        return res.json({
            success: true,
            message: 'Status do pedido atualizado com sucesso',
            order
        });

    } catch (error) {
        console.error('Erro ao atualizar status do pedido:', error);

        const knownErrors = [
            'ID do pedido inválido',
            'Status de pedido inválido',
            'Pedido não encontrado'
        ];

        if (
            knownErrors.includes(error.message) ||
            error.message.startsWith('Não é possível alterar')
        ) {
            return res.status(400).json({
                success: false,
                message: error.message
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao atualizar status do pedido'
        });
    }
}

module.exports = {
    listAllOrders,
    getOrderById,
    updateOrderStatus
};
