const cartService = require('../services/cartService');

async function addToCart(req, res) {
    try {
        const userId = req.user.userId;
        const { productId, quantity } = req.body;

        if (!productId || !quantity) {
            return res.status(400).json({
                success: false,
                message: 'Produto e quantidade são obrigatórios'
            });
        }

        const item = await cartService.addToCart({
            userId,
            productId: Number(productId),
            quantity: Number(quantity)
        });

        return res.status(201).json({
            success: true,
            message: 'Produto adicionado ao carrinho',
            item
        });

    } catch (error) {
        console.error('Erro ao adicionar ao carrinho:', error);

        return res.status(400).json({
            success: false,
            message: error.message
        });
    }
}

async function getCart(req, res) {
    try {
        const userId = req.user.userId;

        const cart = await cartService.getCart(userId);

        return res.json({
            success: true,
            cart
        });

    } catch (error) {
        console.error('Erro ao buscar carrinho:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao buscar carrinho'
        });
    }
}

async function updateCartItem(req, res) {
    try {
        const userId = req.user.userId;
        const { productId } = req.params;
        const { quantity } = req.body;

        if (!quantity) {
            return res.status(400).json({
                success: false,
                message: 'Quantidade é obrigatória'
            });
        }

        const item = await cartService.updateCartItem({
            userId,
            productId: Number(productId),
            quantity: Number(quantity)
        });

        return res.json({
            success: true,
            message: 'Quantidade atualizada',
            item
        });

    } catch (error) {
        console.error('Erro ao atualizar carrinho:', error);

        return res.status(400).json({
            success: false,
            message: error.message
        });
    }
}

async function removeFromCart(req, res) {
    try {
        const userId = req.user.userId;
        const { productId } = req.params;

        await cartService.removeFromCart(
            userId,
            Number(productId)
        );

        return res.json({
            success: true,
            message: 'Produto removido do carrinho'
        });

    } catch (error) {
        console.error('Erro ao remover do carrinho:', error);

        return res.status(400).json({
            success: false,
            message: error.message
        });
    }
}

async function clearCart(req, res) {
    try {
        const userId = req.user.userId;

        await cartService.clearUserCart(userId);

        return res.json({
            success: true,
            message: 'Carrinho limpo'
        });

    } catch (error) {
        console.error('Erro ao limpar carrinho:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao limpar carrinho'
        });
    }
}

module.exports = {
    addToCart,
    getCart,
    updateCartItem,
    removeFromCart,
    clearCart
};
