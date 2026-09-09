const deliveryService =
    require('../services/deliveryService');


// ======================================================
// ADMIN - LISTAR ENTREGAS
// ======================================================

async function listDeliveries(
    req,
    res
) {

    try {

        const deliveries =
            await deliveryService.listAllDeliveries();


        return res.json({
            success: true,
            deliveries
        });


    } catch (error) {

        console.error(
            'Erro ao listar entregas:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao listar entregas'
        });

    }
}


// ======================================================
// ADMIN - BUSCAR ENTREGA
// ======================================================

async function getDelivery(
    req,
    res
) {

    try {

        const deliveryId =
            Number(req.params.id);


        if (
            !Number.isInteger(deliveryId) ||
            deliveryId <= 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'ID da entrega inválido'
            });

        }


        const delivery =
            await deliveryService.getDeliveryById(
                deliveryId
            );


        if (!delivery) {

            return res.status(404).json({
                success: false,
                message:
                    'Entrega não encontrada'
            });

        }


        return res.json({
            success: true,
            delivery
        });


    } catch (error) {

        console.error(
            'Erro ao buscar entrega:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao buscar entrega'
        });

    }
}


// ======================================================
// ADMIN - ATUALIZAR STATUS DA ENTREGA
// ======================================================

async function updateDeliveryStatus(
    req,
    res
) {

    try {

        const deliveryId =
            Number(req.params.id);


        if (
            !Number.isInteger(deliveryId) ||
            deliveryId <= 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'ID da entrega inválido'
            });

        }


        const {
            status,
            notes
        } = req.body;


        if (
            typeof status !== 'string' ||
            status.trim().length === 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'O status da entrega é obrigatório'
            });

        }


        const delivery =
            await deliveryService.changeDeliveryStatus(
                deliveryId,
                status.trim(),
                notes
            );


        if (!delivery) {

            return res.status(404).json({
                success: false,
                message:
                    'Entrega não encontrada'
            });

        }


        return res.json({
            success: true,
            message:
                'Status da entrega atualizado com sucesso',
            delivery
        });


    } catch (error) {

        console.error(
            'Erro ao atualizar entrega:',
            error
        );


        return res.status(400).json({
            success: false,
            message:
                error.message
        });

    }
}


module.exports = {
    listDeliveries,
    getDelivery,
    updateDeliveryStatus
};