require('dotenv').config();

const pool = require('./src/config/database');

async function main() {
    try {
        const result = await pool.query(`
            SELECT *
            FROM deliveries
            ORDER BY order_id DESC
            LIMIT 10
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