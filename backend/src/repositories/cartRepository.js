const pool = require('../config/database');

async function addItem({ userId, productId, quantity }) {
    const result = await pool.query(`
        INSERT INTO cart_items (user_id, product_id, quantity)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, product_id)
        DO UPDATE SET quantity = cart_items.quantity + EXCLUDED.quantity
        RETURNING id, user_id, product_id, quantity, created_at
    `, [userId, productId, quantity]);

    return result.rows[0];
}

async function findByUser(userId) {
    const result = await pool.query(`
        SELECT
            ci.id,
            ci.product_id,
            p.name,
            p.class,
            p.description,
            p.price,
            p.image_url,
            p.stock,
            ci.quantity,
            (p.price * ci.quantity) AS subtotal
        FROM cart_items ci
        INNER JOIN products p ON p.id = ci.product_id
        WHERE ci.user_id = $1
          AND p.active = TRUE
        ORDER BY ci.created_at DESC
    `, [userId]);

    return result.rows;
}

async function findItem(userId, productId) {
    const result = await pool.query(`
        SELECT
            id,
            user_id,
            product_id,
            quantity
        FROM cart_items
        WHERE user_id = $1
          AND product_id = $2
        LIMIT 1
    `, [userId, productId]);

    return result.rows[0] || null;
}

async function updateQuantity({ userId, productId, quantity }) {
    const result = await pool.query(`
        UPDATE cart_items
        SET quantity = $1
        WHERE user_id = $2
          AND product_id = $3
        RETURNING id, user_id, product_id, quantity
    `, [quantity, userId, productId]);

    return result.rows[0] || null;
}

async function removeItem(userId, productId) {
    const result = await pool.query(`
        DELETE FROM cart_items
        WHERE user_id = $1
          AND product_id = $2
        RETURNING id
    `, [userId, productId]);

    return result.rows[0] || null;
}

async function clearCart(userId) {
    await pool.query(`
        DELETE FROM cart_items
        WHERE user_id = $1
    `, [userId]);
}

module.exports = {
    addItem,
    findByUser,
    findItem,
    updateQuantity,
    removeItem,
    clearCart
};

