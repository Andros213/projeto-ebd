const adminUserRepository =
    require('../repositories/adminUserRepository');


// ======================================================
// ADMIN - LISTAR CLIENTES
// ======================================================

async function listAllClients() {

    return await adminUserRepository.listAllClients();

}


// ======================================================
// ADMIN - DETALHES DO CLIENTE
// ======================================================

async function getClientById(clientId) {

    if (
        !Number.isInteger(clientId) ||
        clientId <= 0
    ) {
        throw new Error(
            'ID do cliente inválido'
        );
    }


    return await adminUserRepository.findClientById(
        clientId
    );

}


module.exports = {
    listAllClients,
    getClientById
};