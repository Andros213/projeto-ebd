const adminPaymentService =
    require('../services/adminPaymentService');


// ======================================================
// ADMIN - LISTAR PAGAMENTOS
// ======================================================

async function listPayments(req, res) {

    try {

        const payments =
            await adminPaymentService.listAllPayments();


        return res.json({
            success: true,
            payments
        });


    } catch (error) {

        console.error(
            'Erro ao listar pagamentos:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao listar pagamentos'
        });
    }
}


// ======================================================
// ADMIN - DETALHE DO PAGAMENTO
// ======================================================

async function getPayment(req, res) {

    try {

        const paymentId =
            Number(req.params.id);


        if (
            !Number.isInteger(paymentId) ||
            paymentId <= 0
        ) {

            return res.status(400).json({
                success: false,
                message:
                    'ID do pagamento inválido'
            });
        }


        const payment =
            await adminPaymentService.getPaymentById(
                paymentId
            );


        if (!payment) {

            return res.status(404).json({
                success: false,
                message:
                    'Pagamento não encontrado'
            });
        }


        return res.json({
            success: true,
            payment
        });


    } catch (error) {

        console.error(
            'Erro ao buscar pagamento:',
            error
        );


        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao buscar pagamento'
        });
    }
}


module.exports = {
    listPayments,
    getPayment
};