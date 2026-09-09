const churchRepository = require('../repositories/churchRepository');

async function listChurches(req, res) {
    try {
        const churches = await churchRepository.findAllActive();

        return res.json({
            success: true,
            churches
        });
    } catch (error) {
        console.error('Erro ao buscar igrejas:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao buscar igrejas'
        });
    }
}

async function getChurch(req, res) {
    try {
        const { id } = req.params;

        const church = await churchRepository.findById(id);

        if (!church) {
            return res.status(404).json({
                success: false,
                message: 'Igreja não encontrada'
            });
        }

        return res.json({
            success: true,
            church
        });
    } catch (error) {
        console.error('Erro ao buscar igreja:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao buscar igreja'
        });
    }
}

async function createChurch(req, res) {
    try {
        const { name } = req.body;

        if (!name || !name.trim()) {
            return res.status(400).json({
                success: false,
                message: 'O nome da igreja é obrigatório'
            });
        }

        const church = await churchRepository.create(name.trim());

        return res.status(201).json({
            success: true,
            church
        });
    } catch (error) {
        console.error('Erro ao criar igreja:', error);

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao criar igreja'
        });
    }
}

module.exports = {
    listChurches,
    getChurch,
    createChurch
};