const pool = require('../config/database');


// ======================================================
// ADMIN - LISTAR IGREJAS
// ======================================================

async function listAllChurches() {

    const result = await pool.query(`

        SELECT
            c.id,
            c.name,
            c.active,
            c.created_at,

            COUNT(DISTINCT u.id)::INTEGER AS client_count,

            COUNT(DISTINCT o.id)::INTEGER AS order_count

        FROM churches c

        LEFT JOIN users u
            ON u.church_id = c.id
           AND u.role <> 'admin'

        LEFT JOIN orders o
            ON o.church_id = c.id

        GROUP BY
            c.id,
            c.name,
            c.active,
            c.created_at

        ORDER BY
            c.name ASC

    `);

    return result.rows;
}


// ======================================================
// ADMIN - BUSCAR IGREJA
// ======================================================

async function findChurchById(churchId) {

    const churchResult = await pool.query(`

        SELECT
            id,
            name,
            active,
            created_at

        FROM churches

        WHERE id = $1

        LIMIT 1

    `, [
        churchId
    ]);


    if (churchResult.rows.length === 0) {
        return null;
    }


    const clientsResult = await pool.query(`

        SELECT
            id,
            name,
            email,
            phone,
            active,
            created_at

        FROM users

        WHERE church_id = $1
          AND role <> 'admin'

        ORDER BY name ASC

    `, [
        churchId
    ]);


    const ordersResult = await pool.query(`

        SELECT
            o.id,
            o.user_id,
            o.total,
            o.status,
            o.created_at,

            u.name AS customer_name,

            p.status AS payment_status,
            p.amount AS payment_amount

        FROM orders o

        INNER JOIN users u
            ON u.id = o.user_id

        LEFT JOIN payments p
            ON p.order_id = o.id

        WHERE o.church_id = $1

        ORDER BY o.created_at DESC

    `, [
        churchId
    ]);


    return {
        ...churchResult.rows[0],
        clients: clientsResult.rows,
        orders: ordersResult.rows
    };
}


// ======================================================
// ADMIN - CRIAR IGREJA
// ======================================================

async function createChurch(name) {

    const result = await pool.query(`

        INSERT INTO churches (
            name
        )

        VALUES (
            $1
        )

        RETURNING
            id,
            name,
            active,
            created_at

    `, [
        name
    ]);

    return result.rows[0];
}


// ======================================================
// ADMIN - EDITAR IGREJA
// ======================================================

async function updateChurch(
    churchId,
    name
) {

    const result = await pool.query(`

        UPDATE churches

        SET
            name = $1

        WHERE id = $2

        RETURNING
            id,
            name,
            active,
            created_at

    `, [
        name,
        churchId
    ]);

    return result.rows[0] || null;
}


// ======================================================
// ADMIN - ATIVAR / DESATIVAR
// ======================================================

async function setChurchActive(
    churchId,
    active
) {

    const result = await pool.query(`

        UPDATE churches

        SET
            active = $1

        WHERE id = $2

        RETURNING
            id,
            name,
            active,
            created_at

    `, [
        active,
        churchId
    ]);

    return result.rows[0] || null;
}


// ======================================================
// EXPORT
// ======================================================

module.exports = {
    listAllChurches,
    findChurchById,
    createChurch,
    updateChurch,
    setChurchActive
};