require('dotenv').config();

const pool = require('./src/config/database');

async function main() {
    try {
        const result = await pool.query(`
            SELECT
                column_name,
                data_type,
                is_nullable,
                column_default
            FROM information_schema.columns
            WHERE table_name = 'deliveries'
            ORDER BY ordinal_position
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