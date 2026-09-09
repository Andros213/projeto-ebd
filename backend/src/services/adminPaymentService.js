const adminPaymentRepository =
    require('../repositories/adminPaymentRepository');


// ======================================================
// ADMIN - LISTAR PAGAMENTOS
// ======================================================

async function listAllPayments() {

    return await adminPaymentRepository.listAllPayments();

}


// ======================================================
// ADMIN - BUSCAR PAGAMENTO
// ======================================================

async function getPaymentById(paymentId) {

    if (
        !Number.isInteger(paymentId) ||
        paymentId <= 0
    ) {
        throw new Error(
            'ID do pagamento inválido'
        );
    }


    return await adminPaymentRepository.findPaymentById(
        paymentId
    );
}


module.exports = {
    listAllPayments,
    getPaymentById
};