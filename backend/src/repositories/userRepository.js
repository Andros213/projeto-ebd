const pool = require('../config/database');

async function findByEmail(email) {
    const result = await pool.query(
        `SELECT
            id,
            church_id,
            name,
            email,
            phone,
            password_hash,
            active,
            role,
            created_at
         FROM users
         WHERE email = $1
         LIMIT 1`,
        [email]
    );

    return result.rows[0] || null;
}

async function findById(id) {
    const result = await pool.query(
        `SELECT
            u.id,
            u.church_id,
            u.name,
            u.email,
            u.phone,
            u.active,
            u.role,
            u.created_at,
            c.name AS church_name
         FROM users u
         LEFT JOIN churches c
            ON c.id = u.church_id
         WHERE u.id = $1
         LIMIT 1`,
        [id]
    );

    return result.rows[0] || null;
}

async function updateById({
    userId,
    churchId,
    phone
}) {
    const result = await pool.query(
        `UPDATE users
         SET
            church_id = $1,
            phone = $2
         WHERE id = $3
         RETURNING
            id,
            church_id,
            name,
            email,
            phone,
            active,
            role,
            created_at`,
        [churchId, phone, userId]
    );

    return result.rows[0] || null;
}

async function updateAdminProfile({
    userId,
    name,
    email
}) {
    const result = await pool.query(
        `UPDATE users
         SET
            name = $1,
            email = $2
         WHERE id = $3
           AND role = 'admin'
         RETURNING
            id,
            church_id,
            name,
            email,
            phone,
            active,
            role,
            created_at`,
        [name, email, userId]
    );

    return result.rows[0] || null;
}

async function updatePassword({
    userId,
    passwordHash
}) {
    const result = await pool.query(
        `UPDATE users
         SET password_hash = $1
         WHERE id = $2
           AND role = 'admin'
         RETURNING
            id`,
        [passwordHash, userId]
    );

    return result.rows[0] || null;
}

async function createUser({
    churchId,
    name,
    email,
    phone,
    passwordHash
}) {
    const result = await pool.query(
        `INSERT INTO users (
            church_id,
            name,
            email,
            phone,
            password_hash
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING
            id,
            church_id,
            name,
            email,
            phone,
            active,
            role,
            created_at`,
        [churchId, name, email, phone, passwordHash]
    );

    return result.rows[0];
}

module.exports = {
    findByEmail,
    findById,
    updateById,
    updateAdminProfile,
    updatePassword,
    createUser
};