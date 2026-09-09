require('dotenv').config();

const pool = require('./src/config/database');

async function main() {
    try {

        await pool.query(`
            ALTER TABLE store_settings

            ADD COLUMN IF NOT EXISTS notify_new_order BOOLEAN
                NOT NULL DEFAULT TRUE,

            ADD COLUMN IF NOT EXISTS notify_payment_approved BOOLEAN
                NOT NULL DEFAULT TRUE,

            ADD COLUMN IF NOT EXISTS notify_order_confirmed BOOLEAN
                NOT NULL DEFAULT TRUE,

            ADD COLUMN IF NOT EXISTS notify_order_preparing BOOLEAN
                NOT NULL DEFAULT TRUE,

            ADD COLUMN IF NOT EXISTS notify_order_shipped BOOLEAN
                NOT NULL DEFAULT TRUE,

            ADD COLUMN IF NOT EXISTS notify_order_delivered BOOLEAN
                NOT NULL DEFAULT TRUE
        `);

        console.log(
            'Configurações de notificações adicionadas com sucesso.'
        );

    } catch (error) {

        console.error(
            'Erro ao adicionar configurações de notificações:',
            error
        );

        process.exitCode = 1;

    } finally {

        await pool.end();

    }
}

main();