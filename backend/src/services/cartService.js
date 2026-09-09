const cartRepository = require('../repositories/cartRepository');
const productRepository = require('../repositories/productRepository');

async function addToCart({ userId, productId, quantity }) {
    const product = await productRepository.findById(productId);

    if (!product || !product.active) {
        throw new Error('Produto não encontrado');
    }

    if (product.stock <= 0) {
        throw new Error('Produto sem estoque');
    }

    if (quantity < 1 || quantity > 5) {
        throw new Error('A quantidade deve estar entre 1 e 5');
    }

    const existingItem = await cartRepository.findItem(
        userId,
        productId
    );

    const newQuantity = existingItem
        ? existingItem.quantity + quantity
        : quantity;

    if (newQuantity > 5) {
        throw new Error('A quantidade máxima por produto é 5');
    }

    if (newQuantity > product.stock) {
        throw new Error('Quantidade maior que o estoque disponível');
    }

    return await cartRepository.addItem({
        userId,
        productId,
        quantity
    });
}

async function getCart(userId) {
    const items = await cartRepository.findByUser(userId);

    const total = items.reduce(
        (sum, item) => sum + Number(item.subtotal),
        0
    );

    return {
        items,
        total
    };
}

async function updateCartItem({ userId, productId, quantity }) {
    const product = await productRepository.findById(productId);

    if (!product || !product.active) {
        throw new Error('Produto não encontrado');
    }

    if (quantity < 1 || quantity > 5) {
        throw new Error('A quantidade deve estar entre 1 e 5');
    }

    if (quantity > product.stock) {
        throw new Error('Quantidade maior que o estoque disponível');
    }

    const item = await cartRepository.updateQuantity({
        userId,
        productId,
        quantity
    });

    if (!item) {
        throw new Error('Item não encontrado no carrinho');
    }

    return item;
}

async function removeFromCart(userId, productId) {
    const item = await cartRepository.removeItem(
        userId,
        productId
    );

    if (!item) {
        throw new Error('Item não encontrado no carrinho');
    }

    return item;
}

async function clearUserCart(userId) {
    await cartRepository.clearCart(userId);
}

module.exports = {
    addToCart,
    getCart,
    updateCartItem,
    removeFromCart,
    clearUserCart
};
