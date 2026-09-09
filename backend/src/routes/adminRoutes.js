const express = require('express');

const cloudinaryController =
    require('../controllers/cloudinaryController');


// ======================================================
// CONTROLLER - CONFIGURAÇÕES
// ======================================================

const {
    getSettings,
    updateSettings
} = require('../controllers/adminSettingsController');


// ======================================================
// CONTROLLER - IGREJAS
// ======================================================

const {
    listChurches,
    getChurch,
    createChurch,
    updateChurch,
    setChurchActive
} = require('../controllers/adminChurchController');


// ======================================================
// CONTROLLER - PRODUTOS
// ======================================================

const {
    createProduct,
    listAllProducts,
    updateProduct,
    setProductActive,
    deleteProduct
} = require('../controllers/adminProductController');


// ======================================================
// CONTROLLER - UPLOAD DE IMAGEM
// ======================================================

const {
    uploadProductImage
} = require('../controllers/adminProductUploadController');


// ======================================================
// CONTROLLER - CLIENTES
// ======================================================

const {
    listClients,
    getClient
} = require('../controllers/adminUserController');


// ======================================================
// CONTROLLER - PAGAMENTOS
// ======================================================

const {
    listPayments,
    getPayment
} = require('../controllers/adminPaymentController');


// ======================================================
// CONTROLLER - ENTREGAS
// ======================================================

const {
    listDeliveries,
    getDelivery,
    updateDeliveryStatus
} = require('../controllers/deliveryController');


// ======================================================
// MIDDLEWARES
// ======================================================

const authMiddleware =
    require('../middleware/authMiddleware');

const adminMiddleware =
    require('../middleware/adminMiddleware');

const upload =
    require('../middleware/uploadMiddleware');


// ======================================================
// ROUTER
// ======================================================

const router =
    express.Router();


// ======================================================
// PROTEÇÃO ADMINISTRATIVA
// ======================================================

router.use(
    authMiddleware
);

router.use(
    adminMiddleware
);


// ======================================================
// PRODUTOS
// ======================================================

// Listar todos os produtos

router.get(
    '/products',
    listAllProducts
);


// Cadastrar produto

router.post(
    '/products',
    createProduct
);


// Editar produto

router.put(
    '/products/:id',
    updateProduct
);


// Ativar / desativar produto

router.patch(
    '/products/:id/active',
    setProductActive
);


// Remover produto

router.delete(
    '/products/:id',
    deleteProduct
);


// ======================================================
// UPLOAD DE IMAGEM
// ======================================================

router.post(
    '/products/upload-image',
    upload.single('image'),
    uploadProductImage
);


// ======================================================
// CLIENTES
// ======================================================

// Listar clientes

router.get(
    '/clients',
    listClients
);


// Buscar cliente por ID

router.get(
    '/clients/:id',
    getClient
);


// ======================================================
// PAGAMENTOS
// ======================================================

// Listar pagamentos

router.get(
    '/payments',
    listPayments
);


// Buscar pagamento por ID

router.get(
    '/payments/:id',
    getPayment
);


// ======================================================
// ENTREGAS
// ======================================================

// Listar entregas

router.get(
    '/deliveries',
    listDeliveries
);


// Buscar entrega por ID

router.get(
    '/deliveries/:id',
    getDelivery
);


// Atualizar status da entrega

router.patch(
    '/deliveries/:id/status',
    updateDeliveryStatus
);


// ======================================================
// IGREJAS
// ======================================================

// Listar igrejas

router.get(
    '/churches',
    listChurches
);


// Buscar igreja

router.get(
    '/churches/:id',
    getChurch
);


// Criar igreja

router.post(
    '/churches',
    createChurch
);


// Editar igreja

router.put(
    '/churches/:id',
    updateChurch
);


// Ativar / desativar igreja

router.patch(
    '/churches/:id/active',
    setChurchActive
);


// ======================================================
// CONFIGURAÇÕES
// ======================================================

// Buscar configurações

router.get(
    '/settings',
    getSettings
);


// Atualizar configurações

router.put(
    '/settings',
    updateSettings
);


// ======================================================
// CLOUDINARY
// ======================================================

router.get(
    '/cloudinary/summary',
    cloudinaryController.getCloudinarySummary
);

router.get(
    '/cloudinary/images',
    cloudinaryController.listCloudinaryImages
);

router.delete(
    '/cloudinary/images',
    cloudinaryController.deleteCloudinaryImage
);


// ======================================================
// EXPORT
// ======================================================

module.exports =
    router;