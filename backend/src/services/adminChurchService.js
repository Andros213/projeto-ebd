const adminChurchRepository =
    require('../repositories/adminChurchRepository');


// ======================================================
// ADMIN - LISTAR IGREJAS
// ======================================================

async function listAllChurches() {

    return await adminChurchRepository.listAllChurches();

}


// ======================================================
// ADMIN - BUSCAR IGREJA
// ======================================================

async function getChurchById(churchId) {

    if (
        !Number.isInteger(churchId) ||
        churchId <= 0
    ) {

        throw new Error(
            'ID da igreja inválido'
        );
    }


    return await adminChurchRepository.findChurchById(
        churchId
    );
}


// ======================================================
// ADMIN - CRIAR IGREJA
// ======================================================

async function createChurch(name) {

    if (
        typeof name !== 'string' ||
        name.trim().length === 0
    ) {

        throw new Error(
            'O nome da igreja é obrigatório'
        );
    }


    return await adminChurchRepository.createChurch(
        name.trim()
    );
}


// ======================================================
// ADMIN - EDITAR IGREJA
// ======================================================

async function updateChurch(
    churchId,
    name
) {

    if (
        !Number.isInteger(churchId) ||
        churchId <= 0
    ) {

        throw new Error(
            'ID da igreja inválido'
        );
    }


    if (
        typeof name !== 'string' ||
        name.trim().length === 0
    ) {

        throw new Error(
            'O nome da igreja é obrigatório'
        );
    }


    return await adminChurchRepository.updateChurch(
        churchId,
        name.trim()
    );
}


// ======================================================
// ADMIN - ATIVAR / DESATIVAR
// ======================================================

async function setChurchActive(
    churchId,
    active
) {

    if (
        !Number.isInteger(churchId) ||
        churchId <= 0
    ) {

        throw new Error(
            'ID da igreja inválido'
        );
    }


    if (
        typeof active !== 'boolean'
    ) {

        throw new Error(
            'O campo active deve ser true ou false'
        );
    }


    return await adminChurchRepository.setChurchActive(
        churchId,
        active
    );
}


// ======================================================
// EXPORT
// ======================================================

module.exports = {
    listAllChurches,
    getChurchById,
    createChurch,
    updateChurch,
    setChurchActive
};