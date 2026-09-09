const express = require('express');

const {
    register,
    login,
    me,
    updateProfile,
    updateAdminProfile,
    changeAdminPassword
} = require('../controllers/authController');

const authMiddleware =
    require('../middleware/authMiddleware');

const router = express.Router();

router.post(
    '/register',
    register
);

router.post(
    '/login',
    login
);

router.get(
    '/me',
    authMiddleware,
    me
);

router.put(
    '/me/profile',
    authMiddleware,
    updateProfile
);

router.put(
    '/me/admin-profile',
    authMiddleware,
    updateAdminProfile
);

router.put(
    '/me/admin-password',
    authMiddleware,
    changeAdminPassword
);

module.exports = router;