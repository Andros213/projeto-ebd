const pool = require('../config/database');

async function findAllActive() {
    const result = await pool.query(`
        SELECT
            id,
            name,
            active,
            created_at
        FROM churches
        WHERE active = TRUE
        ORDER BY name ASC
    `);

    return result.rows;
}

async function findById(id) {
    const result = await pool.query(`
        SELECT
            id,
            name,
            active,
            created_at
        FROM churches
        WHERE id = $1
        LIMIT 1
    `, [id]);

    return result.rows[0] || null;
}

async function create(name) {
    const result = await pool.query(`
        INSERT INTO churches (name)
        VALUES ($1)
        RETURNING id, name, active, created_at
    `, [name]);

    return result.rows[0];
}

module.exports = {
    findAllActive,
    findById,
    create
};