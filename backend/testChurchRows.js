require('dotenv').config();

const pool = require('./src/config/database');

async function main() {
    try {
        const result = await pool.query(`
            SELECT
                id,
                name,
                active,
                created_at
            FROM churches
            ORDER BY id ASC
        `);

        console.table(result.rows);

    } catch (error) {
        console.error(error);
        process.exitCode = 1;

    } finally {
        await pool.end();
    }
}

main();