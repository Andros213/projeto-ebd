const express =
    require('express');

const router =
    express.Router();

const authMiddleware =
    require('../middlewares/authMiddleware');

const adminMiddleware =
    require('../middlewares/adminMiddleware');

const cloudinaryController =
    require('../controllers/cloudinaryController');


// ======================================================
// TODAS AS ROTAS EXIGEM ADMIN
// ======================================================

router.use(
    authMiddleware,
    adminMiddleware
);


// ======================================================
// RESUMO
// ======================================================

router.get(
    '/summary',
    cloudinaryController.getCloudinarySummary
);


// ======================================================
// LISTAGEM
// ======================================================

router.get(
    '/images',
    cloudinaryController.listCloudinaryImages
);


// ======================================================
// EXCLUSÃO
// ======================================================

router.delete(
    '/images',
    cloudinaryController.deleteCloudinaryImage
);


module.exports = router;