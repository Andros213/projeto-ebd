const pool = require('../config/database');


// ======================================================
// ADMIN - LISTAR ENTREGAS
// ======================================================

async function listAllDeliveries() {

    const result = await pool.query(`

        SELECT
            d.id,
            d.order_id,
            d.church_id,
            d.status,
            d.notes,
            d.delivered_at,
            d.created_at,
            d.updated_at,

            o.total AS order_total,
            o.status AS order_status,

            u.id AS customer_id,
            u.name AS customer_name,
            u.email AS customer_email,
            u.phone AS customer_phone,

            c.name AS church_name,

            p.status AS payment_status,
            p.amount AS payment_amount,
            p.provider_payment_id

        FROM deliveries d

        INNER JOIN orders o
            ON o.id = d.order_id

        INNER JOIN users u
            ON u.id = o.user_id

        LEFT JOIN churches c
            ON c.id = d.church_id

        LEFT JOIN payments p
            ON p.order_id = d.order_id

        ORDER BY d.created_at DESC

    `);


    return result.rows;
}


// ======================================================
// ADMIN - BUSCAR ENTREGA
// ======================================================

async function findDeliveryById(
    deliveryId
) {

    const result = await pool.query(`

        SELECT
            d.id,
            d.order_id,
            d.church_id,
            d.status,
            d.notes,
            d.delivered_at,
            d.created_at,
            d.updated_at,

            o.total AS order_total,
            o.status AS order_status,

            u.id AS customer_id,
            u.name AS customer_name,
            u.email AS customer_email,
            u.phone AS customer_phone,

            c.name AS church_name,

            p.status AS payment_status,
            p.amount AS payment_amount,
            p.payment_method,
            p.provider_payment_id

        FROM deliveries d

        INNER JOIN orders o
            ON o.id = d.order_id

        INNER JOIN users u
            ON u.id = o.user_id

        LEFT JOIN churches c
            ON c.id = d.church_id

        LEFT JOIN payments p
            ON p.order_id = d.order_id

        WHERE d.id = $1

        LIMIT 1

    `, [
        deliveryId
    ]);


    return result.rows[0] || null;
}


// ======================================================
// ADMIN - ATUALIZAR STATUS DA ENTREGA
// ======================================================

async function updateDeliveryStatus(
    deliveryId,
    status,
    notes
) {

    const client =
        await pool.connect();


    try {

        await client.query('BEGIN');


        const deliveryResult =
            await client.query(`

                SELECT
                    id,
                    order_id,
                    status

                FROM deliveries

                WHERE id = $1

                FOR UPDATE

            `, [
                deliveryId
            ]);


        if (
            deliveryResult.rows.length === 0
        ) {

            await client.query('ROLLBACK');

            return null;
        }


        const delivery =
            deliveryResult.rows[0];


        const deliveredAt =
            status === 'delivered'
                ? new Date()
                : null;


        const updateResult =
            await client.query(`

                UPDATE deliveries

                SET
                    status = $1,
                    notes = $2,
                    delivered_at =
                        CASE
                            WHEN $1 = 'delivered'
                                THEN COALESCE(
                                    delivered_at,
                                    CURRENT_TIMESTAMP
                                )
                            ELSE NULL
                        END,
                    updated_at =
                        CURRENT_TIMESTAMP

                WHERE id = $3

                RETURNING
                    id,
                    order_id,
                    church_id,
                    status,
                    notes,
                    delivered_at,
                    created_at,
                    updated_at

            `, [
                status,
                notes || null,
                deliveryId
            ]);


        // Mantém o status do pedido sincronizado
        // com o fluxo de entrega já utilizado pelo Flutter.
        await client.query(`

            UPDATE orders

            SET
                status = $1,
                updated_at = CURRENT_TIMESTAMP

            WHERE id = $2

        `, [
            status,
            delivery.order_id
        ]);


        await client.query('COMMIT');


        return updateResult.rows[0] || null;


    } catch (error) {

        await client.query('ROLLBACK');

        throw error;

    } finally {

        client.release();

    }
}


module.exports = {
    listAllDeliveries,
    findDeliveryById,
    updateDeliveryStatus
};