const deliveryRepository =
    require('../repositories/deliveryRepository');


// ======================================================
// STATUS PERMITIDOS
// ======================================================

const VALID_STATUSES = [
    'pending',
    'confirmed',
    'preparing',
    'shipped',
    'delivered',
    'cancelled'
];


// ======================================================
// TRANSIÇÕES
// ======================================================

const STATUS_TRANSITIONS = {
    pending: [
        'confirmed',
        'cancelled'
    ],

    confirmed: [
        'preparing',
        'cancelled'
    ],

    preparing: [
        'shipped',
        'cancelled'
    ],

    shipped: [
        'delivered'
    ],

    delivered: [],

    cancelled: []
};


// ======================================================
// LISTAR
// ======================================================

async function listAllDeliveries() {

    return await deliveryRepository
        .listAllDeliveries();

}


// ======================================================
// DETALHE
// ======================================================

async function getDeliveryById(
    deliveryId
) {

    if (
        !Number.isInteger(deliveryId) ||
        deliveryId <= 0
    ) {
        throw new Error(
            'ID da entrega inválido'
        );
    }


    return await deliveryRepository
        .findDeliveryById(
            deliveryId
        );

}


// ======================================================
// ALTERAR STATUS
// ======================================================

async function changeDeliveryStatus(
    deliveryId,
    newStatus,
    notes
) {

    if (
        !Number.isInteger(deliveryId) ||
        deliveryId <= 0
    ) {
        throw new Error(
            'ID da entrega inválido'
        );
    }


    if (
        !VALID_STATUSES.includes(
            newStatus
        )
    ) {
        throw new Error(
            'Status de entrega inválido'
        );
    }


    const delivery =
        await deliveryRepository
            .findDeliveryById(
                deliveryId
            );


    if (!delivery) {
        throw new Error(
            'Entrega não encontrada'
        );
    }


    const allowedTransitions =
        STATUS_TRANSITIONS[
            delivery.status
        ] || [];


    if (
        !allowedTransitions.includes(
            newStatus
        )
    ) {
        throw new Error(
            `Não é possível alterar a entrega de "${delivery.status}" para "${newStatus}"`
        );
    }


    // Uma entrega só deve ser marcada como
    // entregue depois de o pagamento estar aprovado.
    if (
        newStatus === 'delivered' &&
        delivery.payment_status !== 'approved'
    ) {
        throw new Error(
            'A entrega só pode ser concluída após o pagamento ser aprovado'
        );
    }


    return await deliveryRepository
        .updateDeliveryStatus(
            deliveryId,
            newStatus,
            notes
        );

}


module.exports = {
    listAllDeliveries,
    getDeliveryById,
    changeDeliveryStatus
};