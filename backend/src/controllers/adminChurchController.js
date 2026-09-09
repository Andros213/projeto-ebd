const adminChurchService =
    require('../services/adminChurchService');


// ======================================================
// ADMIN - LISTAR IGREJAS
// ======================================================

async function listChurches(
    req,
    res
) {

    try {

        const churches =
            await adminChurchService.listAllChurches();


        return res.json({
            success: true,
            churches
        });


    } catch (error) {

        console.error(
            'Erro ao listar igrejas:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao listar igrejas'
        });
    }
}


// ======================================================
// ADMIN - BUSCAR IGREJA
// ======================================================

async function getChurch(
    req,
    res
) {

    try {

        const churchId =
            Number(req.params.id);


        if (
            !Number.isInteger(churchId) ||
            churchId <= 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'ID da igreja inválido'
            });
        }


        const church =
            await adminChurchService.getChurchById(
                churchId
            );


        if (!church) {

            return res.status(404).json({
                success: false,
                message:
                    'Igreja não encontrada'
            });
        }


        return res.json({
            success: true,
            church
        });


    } catch (error) {

        console.error(
            'Erro ao buscar igreja:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao buscar igreja'
        });
    }
}


// ======================================================
// ADMIN - CRIAR IGREJA
// ======================================================

async function createChurch(
    req,
    res
) {

    try {

        const {
            name
        } = req.body;


        const church =
            await adminChurchService.createChurch(
                name
            );


        return res.status(201).json({
            success: true,
            message:
                'Igreja criada com sucesso',
            church
        });


    } catch (error) {

        console.error(
            'Erro ao criar igreja:',
            error
        );


        return res.status(400).json({
            success: false,
            message:
                error.message
        });
    }
}


// ======================================================
// ADMIN - EDITAR IGREJA
// ======================================================

async function updateChurch(
    req,
    res
) {

    try {

        const churchId =
            Number(req.params.id);


        if (
            !Number.isInteger(churchId) ||
            churchId <= 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'ID da igreja inválido'
            });
        }


        const {
            name
        } = req.body;


        const church =
            await adminChurchService.updateChurch(
                churchId,
                name
            );


        if (!church) {

            return res.status(404).json({
                success: false,
                message:
                    'Igreja não encontrada'
            });
        }


        return res.json({
            success: true,
            message:
                'Igreja atualizada com sucesso',
            church
        });


    } catch (error) {

        console.error(
            'Erro ao atualizar igreja:',
            error
        );


        return res.status(400).json({
            success: false,
            message:
                error.message
        });
    }
}


// ======================================================
// ADMIN - ATIVAR / DESATIVAR
// ======================================================

async function setChurchActive(
    req,
    res
) {

    try {

        const churchId =
            Number(req.params.id);


        if (
            !Number.isInteger(churchId) ||
            churchId <= 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'ID da igreja inválido'
            });
        }


        const {
            active
        } = req.body;


        const church =
            await adminChurchService.setChurchActive(
                churchId,
                active
            );


        if (!church) {

            return res.status(404).json({
                success: false,
                message:
                    'Igreja não encontrada'
            });
        }


        return res.json({
            success: true,

            message:
                active
                    ? 'Igreja ativada com sucesso'
                    : 'Igreja desativada com sucesso',

            church
        });


    } catch (error) {

        console.error(
            'Erro ao alterar status da igreja:',
            error
        );


        return res.status(400).json({
            success: false,
            message:
                error.message
        });
    }
}


// ======================================================
// EXPORT
// ======================================================

module.exports = {
    listChurches,
    getChurch,
    createChurch,
    updateChurch,
    setChurchActive
};