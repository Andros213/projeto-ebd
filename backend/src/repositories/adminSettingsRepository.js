const pool = require('../config/database');


// ======================================================
// ADMIN - BUSCAR CONFIGURAÇÕES DA LOJA
// ======================================================

async function getStoreSettings() {

    const result = await pool.query(`

        SELECT
            id,
            store_name,
            phone,
            email,

            notify_new_order,
            notify_payment_approved,
            notify_order_confirmed,
            notify_order_preparing,
            notify_order_shipped,
            notify_order_delivered,

            created_at,
            updated_at

        FROM store_settings

        WHERE id = 1

        LIMIT 1

    `);

    return result.rows[0] || null;
}


// ======================================================
// ADMIN - ATUALIZAR CONFIGURAÇÕES DA LOJA
// ======================================================

async function updateStoreSettings({
    storeName,
    phone,
    email,

    notifyNewOrder,
    notifyPaymentApproved,
    notifyOrderConfirmed,
    notifyOrderPreparing,
    notifyOrderShipped,
    notifyOrderDelivered
}) {

    const result = await pool.query(`

        INSERT INTO store_settings
        (
            id,
            store_name,
            phone,
            email,

            notify_new_order,
            notify_payment_approved,
            notify_order_confirmed,
            notify_order_preparing,
            notify_order_shipped,
            notify_order_delivered,

            updated_at
        )

        VALUES
        (
            1,
            $1,
            $2,
            $3,

            $4,
            $5,
            $6,
            $7,
            $8,
            $9,

            CURRENT_TIMESTAMP
        )

        ON CONFLICT (id)
        DO UPDATE SET

            store_name =
                EXCLUDED.store_name,

            phone =
                EXCLUDED.phone,

            email =
                EXCLUDED.email,

            notify_new_order =
                EXCLUDED.notify_new_order,

            notify_payment_approved =
                EXCLUDED.notify_payment_approved,

            notify_order_confirmed =
                EXCLUDED.notify_order_confirmed,

            notify_order_preparing =
                EXCLUDED.notify_order_preparing,

            notify_order_shipped =
                EXCLUDED.notify_order_shipped,

            notify_order_delivered =
                EXCLUDED.notify_order_delivered,

            updated_at =
                CURRENT_TIMESTAMP

        RETURNING
            id,
            store_name,
            phone,
            email,

            notify_new_order,
            notify_payment_approved,
            notify_order_confirmed,
            notify_order_preparing,
            notify_order_shipped,
            notify_order_delivered,

            created_at,
            updated_at

    `, [
        storeName,
        phone,
        email,

        notifyNewOrder,
        notifyPaymentApproved,
        notifyOrderConfirmed,
        notifyOrderPreparing,
        notifyOrderShipped,
        notifyOrderDelivered
    ]);

    return result.rows[0];
}


module.exports = {
    getStoreSettings,
    updateStoreSettings
};