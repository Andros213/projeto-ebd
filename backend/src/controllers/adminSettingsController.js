const adminSettingsService =
    require('../services/adminSettingsService');


// ======================================================
// ADMIN - BUSCAR CONFIGURAÇÕES
// ======================================================

async function getSettings(
    req,
    res
) {

    try {

        const settings =
            await adminSettingsService.getStoreSettings();


        if (!settings) {

            return res.status(404).json({
                success: false,
                message:
                    'Configurações da loja não encontradas'
            });
        }


        return res.json({
            success: true,
            settings
        });


    } catch (error) {

        console.error(
            'Erro ao buscar configurações:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao buscar configurações'
        });
    }
}


// ======================================================
// ADMIN - ATUALIZAR CONFIGURAÇÕES
// ======================================================

async function updateSettings(
    req,
    res
) {

    try {

        const {
            storeName,
            phone,
            email,

            notifyNewOrder,
            notifyPaymentApproved,
            notifyOrderConfirmed,
            notifyOrderPreparing,
            notifyOrderShipped,
            notifyOrderDelivered

        } = req.body;


        const settings =
            await adminSettingsService
                .updateStoreSettings({

                    storeName,

                    phone,

                    email,

                    notifyNewOrder,

                    notifyPaymentApproved,

                    notifyOrderConfirmed,

                    notifyOrderPreparing,

                    notifyOrderShipped,

                    notifyOrderDelivered
                });


        return res.json({
            success: true,

            message:
                'Configurações atualizadas com sucesso',

            settings
        });


    } catch (error) {

        console.error(
            'Erro ao atualizar configurações:',
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
    getSettings,
    updateSettings
};