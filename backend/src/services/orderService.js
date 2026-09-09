const orderRepository = require('../repositories/orderRepository');

const VALID_STATUSES = [
    'pending',
    'confirmed',
    'preparing',
    'shipped',
    'delivered',
    'cancelled'
];

const STATUS_TRANSITIONS = {
    pending: ['confirmed', 'cancelled'],
    confirmed: ['preparing', 'cancelled'],
    preparing: ['shipped', 'cancelled'],
    shipped: ['delivered'],
    delivered: [],
    cancelled: []
};

async function createOrder(userId) {
    if (!userId) {
        throw new Error('Usuário não identificado');
    }

    return await orderRepository.createOrderFromCart(userId);
}

async function listAllOrders() {
    return await orderRepository.listAllOrders();
}

async function getOrderById(orderId) {
    if (!Number.isInteger(orderId) || orderId <= 0) {
        throw new Error('ID do pedido inválido');
    }

    return await orderRepository.findOrderById(orderId);
}

async function changeOrderStatus(orderId, newStatus) {
    if (!Number.isInteger(orderId) || orderId <= 0) {
        throw new Error('ID do pedido inválido');
    }

    if (!VALID_STATUSES.includes(newStatus)) {
        throw new Error('Status de pedido inválido');
    }

    const order = await orderRepository.findOrderById(orderId);

    if (!order) {
        throw new Error('Pedido não encontrado');
    }

    const allowedTransitions = STATUS_TRANSITIONS[order.status] || [];

    if (!allowedTransitions.includes(newStatus)) {
        throw new Error(
            `Não é possível alterar o pedido de "${order.status}" para "${newStatus}"`
        );
    }

    return await orderRepository.updateOrderStatus(
        orderId,
        newStatus
    );
}

async function listMyOrders(userId) {
    if (!userId) {
        throw new Error('Usuário não identificado');
    }

    return await orderRepository.listOrdersByUser(userId);
}

async function getMyOrderById(orderId, userId) {
    if (!Number.isInteger(orderId) || orderId <= 0) {
        throw new Error('ID do pedido inválido');
    }

    if (!userId) {
        throw new Error('Usuário não identificado');
    }

    return await orderRepository.findOrderByIdForUser(
        orderId,
        userId
    );
}

module.exports = {
    createOrder,
    listAllOrders,
    getOrderById,
    changeOrderStatus,
    listMyOrders,
    getMyOrderById
};
