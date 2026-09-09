const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const userRepository = require('../repositories/userRepository');
const churchRepository = require('../repositories/churchRepository');

async function registerUser({
    churchId,
    name,
    email,
    phone,
    password
}) {
    const church = await churchRepository.findById(churchId);

    if (!church || !church.active) {
        throw new Error(
            'Igreja não encontrada ou inativa'
        );
    }

    const existingUser =
        await userRepository.findByEmail(email);

    if (existingUser) {
        throw new Error(
            'E-mail já cadastrado'
        );
    }

    const passwordHash =
        await bcrypt.hash(password, 10);

    const user =
        await userRepository.createUser({
            churchId,
            name,
            email,
            phone,
            passwordHash
        });

    return user;
}

async function loginUser({
    email,
    password
}) {
    const user =
        await userRepository.findByEmail(email);

    if (!user) {
        throw new Error(
            'E-mail ou senha inválidos'
        );
    }

    const passwordValid =
        await bcrypt.compare(
            password,
            user.password_hash
        );

    if (!passwordValid) {
        throw new Error(
            'E-mail ou senha inválidos'
        );
    }

    if (!user.active) {
        throw new Error(
            'Usuário inativo'
        );
    }

    const token = jwt.sign(
        {
            userId: user.id,
            churchId: user.church_id,
            email: user.email,
            role: user.role
        },
        process.env.JWT_SECRET,
        {
            expiresIn: '7d'
        }
    );

    return {
        token,
        user: {
            id: user.id,
            churchId: user.church_id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            active: user.active,
            role: user.role
        }
    };
}

async function getCurrentUser(userId) {
    const user =
        await userRepository.findById(userId);

    if (!user) {
        throw new Error(
            'Usuário não encontrado'
        );
    }

    if (!user.active) {
        throw new Error(
            'Usuário inativo'
        );
    }

    return {
        id: user.id,
        churchId: user.church_id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        active: user.active,
        role: user.role,
        churchName: user.church_name,
        createdAt: user.created_at
    };
}

async function updateCurrentUser({
    userId,
    churchId,
    phone
}) {
    const church =
        await churchRepository.findById(churchId);

    if (!church || !church.active) {
        throw new Error(
            'Igreja não encontrada ou inativa'
        );
    }

    const user =
        await userRepository.findById(userId);

    if (!user) {
        throw new Error(
            'Usuário não encontrado'
        );
    }

    if (!user.active) {
        throw new Error(
            'Usuário inativo'
        );
    }

    const updatedUser =
        await userRepository.updateById({
            userId,
            churchId,
            phone
        });

    if (!updatedUser) {
        throw new Error(
            'Não foi possível atualizar o usuário'
        );
    }

    return getCurrentUser(userId);
}

async function updateAdminProfile({
    userId,
    name,
    email
}) {
    const user =
        await userRepository.findById(userId);

    if (!user) {
        throw new Error(
            'Usuário não encontrado'
        );
    }

    if (!user.active) {
        throw new Error(
            'Usuário inativo'
        );
    }

    if (user.role !== 'admin') {
        throw new Error(
            'Acesso permitido apenas para administradores'
        );
    }

    const existingUser =
        await userRepository.findByEmail(email);

    if (
        existingUser &&
        Number(existingUser.id) !== Number(userId)
    ) {
        throw new Error(
            'E-mail já cadastrado'
        );
    }

    const updatedUser =
        await userRepository.updateAdminProfile({
            userId,
            name,
            email
        });

    if (!updatedUser) {
        throw new Error(
            'Não foi possível atualizar a conta administrativa'
        );
    }

    return getCurrentUser(userId);
}

async function changeAdminPassword({
    userId,
    currentPassword,
    newPassword
}) {
    // Primeiro localiza o administrador pelo ID
    // apenas para validar identidade/status.
    const user =
        await userRepository.findById(userId);

    if (!user) {
        throw new Error(
            'Usuário não encontrado'
        );
    }

    if (!user.active) {
        throw new Error(
            'Usuário inativo'
        );
    }

    if (user.role !== 'admin') {
        throw new Error(
            'Acesso permitido apenas para administradores'
        );
    }

    if (
        typeof currentPassword !== 'string' ||
        currentPassword.length === 0
    ) {
        throw new Error(
            'Senha atual não informada'
        );
    }

    if (
        typeof newPassword !== 'string' ||
        newPassword.length === 0
    ) {
        throw new Error(
            'Nova senha não informada'
        );
    }

    if (newPassword.length < 6) {
        throw new Error(
            'A nova senha deve ter pelo menos 6 caracteres'
        );
    }

    // Busca novamente usando findByEmail(),
    // que retorna explicitamente password_hash.
    const userWithPassword =
        await userRepository.findByEmail(
            user.email
        );

    if (!userWithPassword) {
        throw new Error(
            'Não foi possível localizar a conta administrativa'
        );
    }

    if (
        typeof userWithPassword.password_hash !== 'string' ||
        userWithPassword.password_hash.trim().length === 0
    ) {
        throw new Error(
            'Hash da senha administrativa não encontrado'
        );
    }

    const passwordValid =
        await bcrypt.compare(
            currentPassword,
            userWithPassword.password_hash
        );

    if (!passwordValid) {
        throw new Error(
            'Senha atual incorreta'
        );
    }

    const passwordHash =
        await bcrypt.hash(
            newPassword,
            10
        );

    const updatedUser =
        await userRepository.updatePassword({
            userId,
            passwordHash
        });

    if (!updatedUser) {
        throw new Error(
            'Não foi possível alterar a senha'
        );
    }

    return true;
}

module.exports = {
    registerUser,
    loginUser,
    getCurrentUser,
    updateCurrentUser,
    updateAdminProfile,
    changeAdminPassword
};