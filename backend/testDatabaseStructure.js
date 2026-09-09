require('dotenv').config();

const pool = require('./src/config/database');

async function main() {
    try {
        const tables = [
            'users',
            'churches',
            'products',
            'orders',
            'order_items',
            'payments',
            'deliveries',
            'cart_items'
        ];

        for (const table of tables) {
            console.log(`\n===== ${table} =====`);

            const columns = await pool.query(`
                SELECT
                    column_name,
                    data_type,
                    is_nullable,
                    column_default
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = $1
                ORDER BY ordinal_position
            `, [table]);

            console.table(columns.rows);
        }

    } catch (error) {
        console.error(error);
        process.exitCode = 1;

    } finally {
        await pool.end();
    }
}

main();