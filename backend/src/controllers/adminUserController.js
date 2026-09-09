const adminUserService =
    require('../services/adminUserService');


// ======================================================
// ADMIN - LISTAR CLIENTES
// ======================================================

async function listClients(req, res) {

    try {

        const clients =
            await adminUserService.listAllClients();


        return res.json({
            success: true,
            clients
        });


    } catch (error) {

        console.error(
            'Erro ao listar clientes:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao listar clientes'
        });

    }
}


// ======================================================
// ADMIN - DETALHE DO CLIENTE
// ======================================================

async function getClient(req, res) {

    try {

        const clientId =
            Number(req.params.id);


        if (
            !Number.isInteger(clientId) ||
            clientId <= 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'ID do cliente inválido'
            });

        }


        const client =
            await adminUserService.getClientById(
                clientId
            );


        if (!client) {

            return res.status(404).json({
                success: false,
                message:
                    'Cliente não encontrado'
            });

        }


        // Clientes da área ADM não devem abrir
        // contas administrativas como se fossem clientes.
        if (
            client.role &&
            client.role.toString() === 'admin'
        ) {

            return res.status(404).json({
                success: false,
                message:
                    'Cliente não encontrado'
            });

        }


        return res.json({
            success: true,
            client
        });


    } catch (error) {

        console.error(
            'Erro ao buscar cliente:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao buscar cliente'
        });

    }
}


module.exports = {
    listClients,
    getClient
};