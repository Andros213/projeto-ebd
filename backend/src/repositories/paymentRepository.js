const pool = require('../config/database');


async function findByProviderPaymentId(providerPaymentId) {
    const result = await pool.query(
        `
        SELECT
            id,
            order_id,
            provider,
            provider_payment_id,
            status,
            amount,
            payment_method,
            external_reference,
            created_at,
            updated_at
        FROM payments
        WHERE provider = $1
          AND provider_payment_id = $2
        LIMIT 1
        `,
        [
            'mercadopago',
            String(providerPaymentId)
        ]
    );

    return result.rows[0] || null;
}


async function createPayment({
    orderId,
    providerPaymentId,
    status,
    amount,
    paymentMethod,
    externalReference
}) {
    const result = await pool.query(
        `
        INSERT INTO payments
        (
            order_id,
            provider,
            provider_payment_id,
            status,
            amount,
            payment_method,
            external_reference
        )
        VALUES
        (
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            $7
        )
        ON CONFLICT (provider, provider_payment_id)
        DO UPDATE SET
            status = EXCLUDED.status,
            amount = EXCLUDED.amount,
            payment_method = EXCLUDED.payment_method,
            external_reference = EXCLUDED.external_reference,
            updated_at = CURRENT_TIMESTAMP
        RETURNING
            id,
            order_id,
            provider,
            provider_payment_id,
            status,
            amount,
            payment_method,
            external_reference,
            created_at,
            updated_at
        `,
        [
            orderId,
            'mercadopago',
            String(providerPaymentId),
            status,
            amount,
            paymentMethod,
            externalReference
        ]
    );

    return result.rows[0];
}


module.exports = {
    findByProviderPaymentId,
    createPayment
};