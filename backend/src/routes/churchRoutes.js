const express = require('express');

const {
    listChurches,
    getChurch,
    createChurch
} = require('../controllers/churchController');

const router = express.Router();

router.get('/', listChurches);
router.get('/:id', getChurch);
router.post('/', createChurch);

module.exports = router;