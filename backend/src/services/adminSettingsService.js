const adminSettingsRepository =
    require('../repositories/adminSettingsRepository');


// ======================================================
// ADMIN - BUSCAR CONFIGURAÇÕES
// ======================================================

async function getStoreSettings() {

    return await adminSettingsRepository.getStoreSettings();

}


// ======================================================
// ADMIN - ATUALIZAR CONFIGURAÇÕES
// ======================================================

async function updateStoreSettings({
    storeName,
    phone,
    email,

    notifyNewOrder,
    notifyPaymentApproved,
    notifyOrderConfirmed,
    notifyOrderPreparing,
    notifyOrderShipped,
    notifyOrderDelivered
}) {

    // ==================================================
    // NOME DA LOJA
    // ==================================================

    if (
        typeof storeName !== 'string' ||
        storeName.trim().length === 0
    ) {

        throw new Error(
            'O nome da loja é obrigatório'
        );
    }


    // ==================================================
    // TELEFONE
    // ==================================================

    if (
        phone !== null &&
        phone !== undefined &&
        typeof phone !== 'string'
    ) {

        throw new Error(
            'Telefone inválido'
        );
    }


    // ==================================================
    // E-MAIL
    // ==================================================

    if (
        email !== null &&
        email !== undefined &&
        typeof email !== 'string'
    ) {

        throw new Error(
            'E-mail inválido'
        );
    }


    // ==================================================
    // NOTIFICAÇÕES
    // ==================================================

    const notifications = [
        notifyNewOrder,
        notifyPaymentApproved,
        notifyOrderConfirmed,
        notifyOrderPreparing,
        notifyOrderShipped,
        notifyOrderDelivered
    ];


    for (
        const value
        of notifications
    ) {

        if (typeof value !== 'boolean') {

            throw new Error(
                'As configurações de notificações devem ser booleanas'
            );
        }
    }


    // ==================================================
    // NORMALIZAÇÃO
    // ==================================================

    const normalizedPhone =
        phone === null ||
        phone === undefined ||
        phone.trim().length === 0

            ? null

            : phone.trim();


    const normalizedEmail =
        email === null ||
        email === undefined ||
        email.trim().length === 0

            ? null

            : email.trim().toLowerCase();


    // ==================================================
    // SALVAR
    // ==================================================

    return await adminSettingsRepository
        .updateStoreSettings({

            storeName:
                storeName.trim(),

            phone:
                normalizedPhone,

            email:
                normalizedEmail,

            notifyNewOrder:
                notifyNewOrder,

            notifyPaymentApproved:
                notifyPaymentApproved,

            notifyOrderConfirmed:
                notifyOrderConfirmed,

            notifyOrderPreparing:
                notifyOrderPreparing,

            notifyOrderShipped:
                notifyOrderShipped,

            notifyOrderDelivered:
                notifyOrderDelivered

        });

}


module.exports = {
    getStoreSettings,
    updateStoreSettings
};