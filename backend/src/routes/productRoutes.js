const express = require('express');

const {
    listProducts,
    getProduct
} = require('../controllers/productController');

const router = express.Router();

// Lista todas as revistas/produtos ativos
router.get('/', listProducts);

// Busca uma revista/produto pelo ID
router.get('/:id', getProduct);

module.exports = router;
