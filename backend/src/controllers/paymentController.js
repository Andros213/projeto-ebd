const mercadoPagoService = require('../services/mercadoPagoService');


async function createPreference(req, res) {
    try {
        const userId = req.user.userId;
        const orderId = Number(req.params.orderId);


        if (
            !Number.isInteger(orderId) ||
            orderId <= 0
        ) {
            return res.status(400).json({
                success: false,
                message: 'ID do pedido inválido'
            });
        }


        const order =
            await mercadoPagoService.getOrderForUser(
                orderId,
                userId
            );


        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Pedido não encontrado'
            });
        }


        const preference =
            await mercadoPagoService.createPreference(
                order
            );


        return res.status(201).json({
            success: true,
            message: 'Preferência de pagamento criada',
            preference
        });

    } catch (error) {
        console.error(
            'Erro ao criar preferência de pagamento:',
            error
        );


        return res.status(400).json({
            success: false,
            message: error.message
        });
    }
}


module.exports = {
    createPreference
};