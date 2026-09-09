const pool = require('../config/database');


// ======================================================
// ADMIN - LISTAR CLIENTES
// ======================================================

async function listAllClients() {

    const result = await pool.query(`

        SELECT
            u.id,
            u.name,
            u.email,
            u.phone,
            u.active,
            u.role,
            u.created_at,

            c.id AS church_id,
            c.name AS church_name,

            COUNT(DISTINCT o.id)::INTEGER AS order_count,

            COALESCE(
                SUM(
                    CASE
                        WHEN p.status = 'approved'
                        THEN p.amount
                        ELSE 0
                    END
                ),
                0
            ) AS approved_total

        FROM users u

        LEFT JOIN churches c
            ON c.id = u.church_id

        LEFT JOIN orders o
            ON o.user_id = u.id

        LEFT JOIN payments p
            ON p.order_id = o.id

        WHERE u.role <> 'admin'

        GROUP BY
            u.id,
            u.name,
            u.email,
            u.phone,
            u.active,
            u.role,
            u.created_at,
            c.id,
            c.name

        ORDER BY u.created_at DESC

    `);


    return result.rows;
}


// ======================================================
// ADMIN - BUSCAR CLIENTE
// ======================================================

async function findClientById(clientId) {

    const clientResult = await pool.query(`

        SELECT
            u.id,
            u.name,
            u.email,
            u.phone,
            u.active,
            u.role,
            u.created_at,

            c.id AS church_id,
            c.name AS church_name

        FROM users u

        LEFT JOIN churches c
            ON c.id = u.church_id

        WHERE u.id = $1

        LIMIT 1

    `, [
        clientId
    ]);


    if (clientResult.rows.length === 0) {
        return null;
    }


    const ordersResult = await pool.query(`

        SELECT
            o.id,
            o.total,
            o.status,
            o.created_at,
            o.updated_at,

            p.status AS payment_status,
            p.amount AS payment_amount,
            p.payment_method,
            p.provider_payment_id

        FROM orders o

        LEFT JOIN payments p
            ON p.order_id = o.id

        WHERE o.user_id = $1

        ORDER BY o.created_at DESC

    `, [
        clientId
    ]);


    return {
        ...clientResult.rows[0],

        orders: ordersResult.rows
    };
}


module.exports = {
    listAllClients,
    findClientById
};