const authService = require('../services/authService');

async function register(req, res) {
    try {
        const {
            churchId,
            name,
            email,
            phone,
            password
        } = req.body;

        const parsedChurchId = Number(churchId);

        if (
            !Number.isInteger(parsedChurchId) ||
            parsedChurchId <= 0
        ) {
            return res.status(400).json({
                success: false,
                message: 'Uma igreja válida deve ser selecionada'
            });
        }

        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Nome, e-mail e senha são obrigatórios'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'A senha deve ter pelo menos 6 caracteres'
            });
        }

        const user = await authService.registerUser({
            churchId: parsedChurchId,
            name: name.trim(),
            email: email.trim().toLowerCase(),
            phone: phone ? phone.trim() : null,
            password
        });

        return res.status(201).json({
            success: true,
            message: 'Usuário cadastrado com sucesso',
            user
        });

    } catch (error) {
        console.error('Erro no cadastro:', error);

        if (error.message === 'E-mail já cadastrado') {
            return res.status(409).json({
                success: false,
                message: error.message
            });
        }

        if (error.message === 'Igreja não encontrada ou inativa') {
            return res.status(400).json({
                success: false,
                message: error.message
            });
        }

        if (error.code === '23503') {
            return res.status(400).json({
                success: false,
                message: 'A igreja selecionada não existe'
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao cadastrar usuário'
        });
    }
}

async function login(req, res) {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'E-mail e senha são obrigatórios'
            });
        }

        const result = await authService.loginUser({
            email: email.trim().toLowerCase(),
            password
        });

        return res.json({
            success: true,
            message: 'Login realizado com sucesso',
            user: result
        });

    } catch (error) {
        console.error('Erro no login:', error);

        if (
            error.message === 'E-mail ou senha inválidos' ||
            error.message === 'Usuário inativo'
        ) {
            return res.status(401).json({
                success: false,
                message: error.message
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao realizar login'
        });
    }
}

async function me(req, res) {
    try {
        const userId = Number(req.user?.userId);

        if (
            !Number.isInteger(userId) ||
            userId <= 0
        ) {
            return res.status(401).json({
                success: false,
                message: 'Usuário autenticado inválido'
            });
        }

        const user =
            await authService.getCurrentUser(userId);

        return res.json({
            success: true,
            user
        });

    } catch (error) {
        console.error(
            'Erro ao obter usuário autenticado:',
            error
        );

        if (
            error.message === 'Usuário não encontrado' ||
            error.message === 'Usuário inativo'
        ) {
            return res.status(401).json({
                success: false,
                message: error.message
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Erro interno ao obter usuário'
        });
    }
}

async function updateProfile(req, res) {
    try {
        const userId = Number(req.user?.userId);

        if (
            !Number.isInteger(userId) ||
            userId <= 0
        ) {
            return res.status(401).json({
                success: false,
                message: 'Usuário autenticado inválido'
            });
        }

        const parsedChurchId =
            Number(req.body.churchId);

        if (
            !Number.isInteger(parsedChurchId) ||
            parsedChurchId <= 0
        ) {
            return res.status(400).json({
                success: false,
                message:
                    'Uma igreja válida deve ser selecionada'
            });
        }

        const rawPhone = req.body.phone;

        const phone =
            rawPhone === null ||
            rawPhone === undefined ||
            rawPhone.toString().trim() === ''
                ? null
                : rawPhone.toString().trim();

        const user =
            await authService.updateCurrentUser({
                userId,
                churchId: parsedChurchId,
                phone
            });

        return res.json({
            success: true,
            message:
                'Dados da conta atualizados com sucesso',
            user
        });

    } catch (error) {
        console.error(
            'Erro ao atualizar conta:',
            error
        );

        if (
            error.message === 'Usuário não encontrado' ||
            error.message === 'Usuário inativo'
        ) {
            return res.status(401).json({
                success: false,
                message: error.message
            });
        }

        if (
            error.message ===
            'Igreja não encontrada ou inativa'
        ) {
            return res.status(400).json({
                success: false,
                message: error.message
            });
        }

        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao atualizar conta'
        });
    }
}

async function updateAdminProfile(req, res) {
    try {
        const userId = Number(req.user?.userId);

        if (
            !Number.isInteger(userId) ||
            userId <= 0
        ) {
            return res.status(401).json({
                success: false,
                message:
                    'Usuário autenticado inválido'
            });
        }

        if (req.user?.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message:
                    'Acesso permitido apenas para administradores'
            });
        }

        const name =
            req.body.name?.toString().trim();

        const email =
            req.body.email?.toString().trim().toLowerCase();

        if (!name || !email) {
            return res.status(400).json({
                success: false,
                message:
                    'Nome e e-mail são obrigatórios'
            });
        }

        const user =
            await authService.updateAdminProfile({
                userId,
                name,
                email
            });

        return res.json({
            success: true,
            message:
                'Conta administrativa atualizada com sucesso',
            user
        });

    } catch (error) {
        console.error(
            'Erro ao atualizar conta administrativa:',
            error
        );

        if (
            error.message === 'E-mail já cadastrado'
        ) {
            return res.status(409).json({
                success: false,
                message: error.message
            });
        }

        if (
            error.message === 'Usuário não encontrado' ||
            error.message === 'Usuário inativo'
        ) {
            return res.status(401).json({
                success: false,
                message: error.message
            });
        }

        if (
            error.message ===
            'Acesso permitido apenas para administradores'
        ) {
            return res.status(403).json({
                success: false,
                message: error.message
            });
        }

        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao atualizar conta administrativa'
        });
    }
}

async function changeAdminPassword(req, res) {
    try {
        const userId = Number(req.user?.userId);

        if (
            !Number.isInteger(userId) ||
            userId <= 0
        ) {
            return res.status(401).json({
                success: false,
                message:
                    'Usuário autenticado inválido'
            });
        }

        if (req.user?.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message:
                    'Acesso permitido apenas para administradores'
            });
        }

        const currentPassword =
            req.body.currentPassword?.toString();

        const newPassword =
            req.body.newPassword?.toString();

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message:
                    'Senha atual e nova senha são obrigatórias'
            });
        }

        await authService.changeAdminPassword({
            userId,
            currentPassword,
            newPassword
        });

        return res.json({
            success: true,
            message:
                'Senha administrativa alterada com sucesso'
        });

    } catch (error) {
        console.error(
            'Erro ao alterar senha administrativa:',
            error
        );

        if (
            error.message === 'Senha atual incorreta'
        ) {
            return res.status(401).json({
                success: false,
                message: error.message
            });
        }

        if (
            error.message ===
            'A nova senha deve ter pelo menos 6 caracteres'
        ) {
            return res.status(400).json({
                success: false,
                message: error.message
            });
        }

        if (
            error.message ===
            'Acesso permitido apenas para administradores'
        ) {
            return res.status(403).json({
                success: false,
                message: error.message
            });
        }

        if (
            error.message === 'Usuário não encontrado' ||
            error.message === 'Usuário inativo'
        ) {
            return res.status(401).json({
                success: false,
                message: error.message
            });
        }

        return res.status(500).json({
            success: false,
            message:
                'Erro interno ao alterar senha administrativa'
        });
    }
}

module.exports = {
    register,
    login,
    me,
    updateProfile,
    updateAdminProfile,
    changeAdminPassword
};