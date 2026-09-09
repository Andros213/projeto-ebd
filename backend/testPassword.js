require('dotenv').config();

const pool = require('./src/config/database');

async function test() {
    try {
        const result = await pool.query(
            `SELECT
                id,
                email,
                role,
                active,
                password_hash
             FROM users
             WHERE role = 'admin'
             LIMIT 10`
        );

        console.log(
            result.rows.map((user) => ({
                id: user.id,
                email: user.email,
                role: user.role,
                active: user.active,
                hasHash: Boolean(user.password_hash),
                hashLength: user.password_hash
                    ? user.password_hash.length
                    : null
            }))
        );
    } catch (error) {
        console.error(error);
    } finally {
        await pool.end();
    }
}

test();