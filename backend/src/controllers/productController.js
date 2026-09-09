const productRepository = require('../repositories/productRepository');

async function listProducts(req, res) {
    try {
        const products = await productRepository.findAllActive();

        return res.json({
            success: true,
            products
        });
    } catch (error) {
        console.error('Erro ao buscar produtos:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao buscar produtos'
        });
    }
}

async function getProduct(req, res) {
    try {
        const { id } = req.params;

        const product = await productRepository.findById(id);

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Produto não encontrado'
            });
        }

        return res.json({
            success: true,
            product
        });
    } catch (error) {
        console.error('Erro ao buscar produto:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao buscar produto'
        });
    }
}

module.exports = {
    listProducts,
    getProduct
};
