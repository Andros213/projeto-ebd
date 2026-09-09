const pool = require('../config/database');


// ======================================================
// ADMIN - LISTAR PAGAMENTOS
// ======================================================

async function listAllPayments() {

    const result = await pool.query(`

        SELECT
            p.id,
            p.order_id,
            p.provider,
            p.provider_payment_id,
            p.status,
            p.amount,
            p.payment_method,
            p.external_reference,
            p.created_at,
            p.updated_at,

            u.id AS customer_id,
            u.name AS customer_name,
            u.email AS customer_email,
            u.phone AS customer_phone,

            c.id AS church_id,
            c.name AS church_name

        FROM payments p

        INNER JOIN orders o
            ON o.id = p.order_id

        INNER JOIN users u
            ON u.id = o.user_id

        LEFT JOIN churches c
            ON c.id = o.church_id

        ORDER BY p.created_at DESC

    `);

    return result.rows;
}


// ======================================================
// ADMIN - BUSCAR PAGAMENTO
// ======================================================

async function findPaymentById(paymentId) {

    const result = await pool.query(`

        SELECT
            p.id,
            p.order_id,
            p.provider,
            p.provider_payment_id,
            p.status,
            p.amount,
            p.payment_method,
            p.external_reference,
            p.created_at,
            p.updated_at,

            u.id AS customer_id,
            u.name AS customer_name,
            u.email AS customer_email,
            u.phone AS customer_phone,

            c.id AS church_id,
            c.name AS church_name,

            o.status AS order_status,
            o.total AS order_total,
            o.created_at AS order_created_at

        FROM payments p

        INNER JOIN orders o
            ON o.id = p.order_id

        INNER JOIN users u
            ON u.id = o.user_id

        LEFT JOIN churches c
            ON c.id = o.church_id

        WHERE p.id = $1

        LIMIT 1

    `, [
        paymentId
    ]);

    return result.rows[0] || null;
}


module.exports = {
    listAllPayments,
    findPaymentById
};