function adminMiddleware(req, res, next) {
    if (!req.user) {
        return res.status(401).json({
            success: false,
            message: 'Usuário não autenticado'
        });
    }

    if (req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            message: 'Acesso permitido apenas para administradores'
        });
    }

    next();
}

module.exports = adminMiddleware;
