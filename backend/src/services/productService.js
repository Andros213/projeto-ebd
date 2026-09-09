const pool = require('../config/database');

const cloudinaryService =
    require('./cloudinaryService');


// ======================================================
// CRIAR PRODUTO
// ======================================================

async function createProduct({
    name,
    type,
    className,
    description,
    price,
    imageUrl,
    stock
}) {

    const result = await pool.query(`

        INSERT INTO products (
            name,
            type,
            class,
            description,
            price,
            image_url,
            stock,
            active
        )

        VALUES ($1,$2,$3,$4,$5,$6,$7,TRUE)

        RETURNING
            id,
            name,
            type,
            class,
            description,
            price,
            image_url,
            stock,
            active,
            created_at,
            updated_at

    `,
    [
        name,
        type,
        className,
        description,
        price,
        imageUrl,
        stock
    ]);


    return result.rows[0];

}


// ======================================================
// LISTAR PRODUTOS
// ======================================================

async function listAllProducts() {

    const result = await pool.query(`

        SELECT
            id,
            name,
            type,
            class,
            description,
            price,
            image_url,
            stock,
            active,
            created_at,
            updated_at

        FROM products

        ORDER BY created_at DESC

    `);


    return result.rows;

}


// ======================================================
// ATUALIZAR PRODUTO
// ======================================================

async function updateProduct(
    id,
    {
        name,
        type,
        className,
        description,
        price,
        imageUrl,
        stock
    }
) {

    // ==================================================
    // BUSCAR IMAGEM ATUAL
    // ==================================================

    const currentResult = await pool.query(`

        SELECT
            id,
            image_url

        FROM products

        WHERE id = $1

        LIMIT 1

    `,
    [
        id
    ]);


    if (currentResult.rows.length === 0) {
        return null;
    }


    const currentProduct =
        currentResult.rows[0];


    const oldImageUrl =
        currentProduct.image_url
            ?.toString()
            .trim() || null;


    const newImageUrl =
        imageUrl
            ?.toString()
            .trim() || null;


    // ==================================================
    // ATUALIZAR PRODUTO NO BANCO
    // ==================================================

    const result = await pool.query(`

        UPDATE products

        SET
            name = $1,
            type = $2,
            class = $3,
            description = $4,
            price = $5,
            image_url = $6,
            stock = $7,
            updated_at = CURRENT_TIMESTAMP

        WHERE id = $8

        RETURNING
            id,
            name,
            type,
            class,
            description,
            price,
            image_url,
            stock,
            active,
            created_at,
            updated_at

    `,
    [
        name,
        type,
        className,
        description,
        price,
        newImageUrl,
        stock,
        id
    ]);


    const updatedProduct =
        result.rows[0] || null;


    if (!updatedProduct) {
        return null;
    }


    // ==================================================
    // VERIFICAR SE A IMAGEM MUDOU
    // ==================================================

    const imageChanged =
        oldImageUrl &&
        oldImageUrl !== newImageUrl;


    if (!imageChanged) {
        return updatedProduct;
    }


    // ==================================================
    // VERIFICAR SE OUTRO PRODUTO USA A IMAGEM ANTIGA
    // ==================================================

    try {

        const otherProductsResult =
            await pool.query(`

                SELECT
                    id

                FROM products

                WHERE image_url = $1
                  AND id <> $2

                LIMIT 1

            `,
            [
                oldImageUrl,
                id
            ]);


        const anotherProductUsesImage =
            otherProductsResult.rows.length > 0;


        // ==================================================
        // EXCLUIR IMAGEM ANTIGA
        // ==================================================

        if (!anotherProductUsesImage) {

            const deletionResult =
                await cloudinaryService.deleteImageByUrl(
                    oldImageUrl
                );


            if (deletionResult.deleted) {

                console.log(
                    'Imagem antiga removida do Cloudinary:',
                    deletionResult.publicId
                );

            } else {

                console.log(
                    'A imagem antiga não pôde ser convertida em Public ID:',
                    oldImageUrl
                );

            }

        } else {

            console.log(
                'Imagem antiga mantida porque outro produto ainda a utiliza:',
                oldImageUrl
            );

        }

    } catch (error) {

        // ==================================================
        // NÃO CANCELAR A ATUALIZAÇÃO
        // ==================================================

        console.error(
            'Não foi possível remover a imagem antiga do Cloudinary:',
            error.message
        );

    }


    return updatedProduct;

}


// ======================================================
// ATIVAR / DESATIVAR PRODUTO
// ======================================================

async function setProductActive(
    id,
    active
) {

    const result = await pool.query(`

        UPDATE products

        SET
            active = $1,
            updated_at = CURRENT_TIMESTAMP

        WHERE id = $2

        RETURNING
            id,
            name,
            type,
            class,
            description,
            price,
            image_url,
            stock,
            active,
            created_at,
            updated_at

    `,
    [
        active,
        id
    ]);


    return result.rows[0] || null;

}


// ======================================================
// EXCLUIR PRODUTO
// ======================================================

async function deleteProduct(id) {

    // ==================================================
    // BUSCAR PRODUTO
    // ==================================================

    const productResult = await pool.query(`

        SELECT
            id,
            name,
            image_url

        FROM products

        WHERE id = $1

        LIMIT 1

    `,
    [
        id
    ]);


    if (productResult.rows.length === 0) {

        return {
            deleted: false,
            reason: 'not_found'
        };

    }


    const product =
        productResult.rows[0];


    // ==================================================
    // VERIFICAR HISTÓRICO DE PEDIDOS
    // ==================================================

    const orderResult = await pool.query(`

        SELECT
            1

        FROM order_items

        WHERE product_id = $1

        LIMIT 1

    `,
    [
        id
    ]);


    if (orderResult.rows.length > 0) {

        return {
            deleted: false,
            reason: 'has_orders',
            product
        };

    }


    // ==================================================
    // VERIFICAR SE OUTRO PRODUTO USA A MESMA IMAGEM
    // ==================================================

    const imageUrl =
        product.image_url
            ?.toString()
            .trim() || null;


    let anotherProductUsesImage = false;


    if (imageUrl) {

        const imageUsageResult =
            await pool.query(`

                SELECT
                    1

                FROM products

                WHERE image_url = $1
                  AND id <> $2

                LIMIT 1

            `,
            [
                imageUrl,
                id
            ]);


        anotherProductUsesImage =
            imageUsageResult.rows.length > 0;
    }


    // ==================================================
    // EXCLUIR PRODUTO
    // ==================================================

    const deleteResult = await pool.query(`

        DELETE FROM products

        WHERE id = $1

        RETURNING
            id,
            name,
            image_url

    `,
    [
        id
    ]);


    const deletedProduct =
        deleteResult.rows[0] || null;


    if (!deletedProduct) {

        return {
            deleted: false,
            reason: 'not_found'
        };

    }


    // ==================================================
    // EXCLUIR IMAGEM DO CLOUDINARY
    // ==================================================

    if (
        imageUrl &&
        !anotherProductUsesImage
    ) {

        try {

            const deletionResult =
                await cloudinaryService.deleteImageByUrl(
                    imageUrl
                );


            if (deletionResult.deleted) {

                console.log(
                    'Imagem do produto removida do Cloudinary:',
                    deletionResult.publicId
                );

            }

        } catch (error) {

            // ==================================================
            // PRODUTO JÁ FOI EXCLUÍDO
            // ==================================================

            console.error(
                'Produto excluído, mas não foi possível remover a imagem do Cloudinary:',
                error.message
            );

        }

    } else if (anotherProductUsesImage) {

        console.log(
            'Imagem mantida porque outro produto ainda a utiliza:',
            imageUrl
        );

    }


    return {
        deleted: true,
        product: deletedProduct
    };

}


// ======================================================
// EXPORTS
// ======================================================

module.exports = {
    createProduct,
    listAllProducts,
    updateProduct,
    setProductActive,
    deleteProduct
};