const express = require('express');

const {
    addToCart,
    getCart,
    updateCartItem,
    removeFromCart,
    clearCart
} = require('../controllers/cartController');

const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Todas as rotas do carrinho exigem usuário logado
router.use(authMiddleware);

// Ver carrinho
router.get('/', getCart);

// Adicionar produto
router.post('/', addToCart);

// Alterar quantidade
router.put('/:productId', updateCartItem);

// Remover produto
router.delete('/:productId', removeFromCart);

// Limpar carrinho
router.delete('/', clearCart);

module.exports = router;
