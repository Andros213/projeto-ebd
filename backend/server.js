require('dotenv').config();

const express = require('express');
const cors = require('cors');

const pool = require('./src/config/database');

const churchRoutes = require('./src/routes/churchRoutes');
const authRoutes = require('./src/routes/authRoutes');
const productRoutes = require('./src/routes/productRoutes');
const cartRoutes = require('./src/routes/cartRoutes');
const orderRoutes = require('./src/routes/orderRoutes');
const paymentRoutes = require('./src/routes/paymentRoutes');

const adminRoutes = require('./src/routes/adminRoutes');
const adminOrderRoutes = require('./src/routes/adminOrderRoutes');

const webhookRoutes = require('./src/routes/webhookRoutes');
const whatsappWebhookRoutes = require('./src/routes/whatsappWebhookRoutes');


const app = express();

const PORT = process.env.PORT || 3000;


app.use(cors());

app.use(express.json());


// ======================================================
// ROTAS PRINCIPAIS
// ======================================================

app.use(
    '/api/churches',
    churchRoutes
);

app.use(
    '/api/auth',
    authRoutes
);

app.use(
    '/api/products',
    productRoutes
);

app.use(
    '/api/cart',
    cartRoutes
);

app.use(
    '/api/orders',
    orderRoutes
);

app.use(
    '/api/payments',
    paymentRoutes
);


// ======================================================
// ROTAS ADMINISTRATIVAS
// ======================================================

app.use(
    '/api/admin',
    adminRoutes
);

app.use(
    '/api/admin/orders',
    adminOrderRoutes
);


// ======================================================
// WEBHOOKS
// ======================================================

app.use(
    '/api/webhooks/mercadopago',
    webhookRoutes
);

app.use(
    '/api/webhooks/whatsapp',
    whatsappWebhookRoutes
);


// ======================================================
// ROTA PRINCIPAL
// ======================================================

app.get(
    '/',
    (req, res) => {

        res.json({
            success: true,
            message: 'API EBD V2 funcionando'
        });

    }
);


// ======================================================
// HEALTH CHECK
// ======================================================

app.get(
    '/api/health',
    async (req, res) => {

        try {

            const result =
                await pool.query(
                    'SELECT NOW() AS now'
                );


            res.json({
                success: true,
                api: 'online',
                database: 'online',
                time: result.rows[0].now
            });


        } catch (error) {

            console.error(
                'Erro PostgreSQL:',
                error
            );


            res.status(500).json({
                success: false,
                api: 'online',
                database: 'offline'
            });
        }
    }
);


// ======================================================
// SERVIDOR
// ======================================================

app.listen(
    PORT,
    () => {

        console.log(
            `API EBD V2 rodando na porta ${PORT}`
        );

    }
);