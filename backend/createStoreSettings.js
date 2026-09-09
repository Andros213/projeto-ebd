require('dotenv').config();

const pool = require('./src/config/database');

async function main() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS store_settings (
                id INTEGER PRIMARY KEY DEFAULT 1,
                store_name VARCHAR(150) NOT NULL,
                phone VARCHAR(30),
                email VARCHAR(150),
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            INSERT INTO store_settings (
                id,
                store_name,
                phone,
                email
            )
            VALUES (
                1,
                'EBD V2',
                NULL,
                NULL
            )
            ON CONFLICT (id)
            DO NOTHING;
        `);

        console.log('Tabela store_settings criada/verificada com sucesso.');

    } catch (error) {
        console.error('Erro ao criar store_settings:', error);
        process.exitCode = 1;

    } finally {
        await pool.end();
    }
}

main();