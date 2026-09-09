const { v2: cloudinary } = require('cloudinary');

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

const PRODUCT_IMAGE_FOLDER = 'ebd-v2/products';


// ======================================================
// ENVIAR IMAGEM
// ======================================================

function uploadImage(buffer, options = {}) {
    return new Promise((resolve, reject) => {

        const uploadStream =
            cloudinary.uploader.upload_stream(
                {
                    folder:
                        options.folder ||
                        PRODUCT_IMAGE_FOLDER,

                    resource_type: 'image'
                },

                (error, result) => {

                    if (error) {
                        reject(error);
                        return;
                    }

                    resolve(result);
                }
            );

        uploadStream.end(buffer);
    });
}


// ======================================================
// BUSCAR USO DA CONTA
// ======================================================

async function getUsage() {

    const result =
        await cloudinary.api.usage();

    return result;
}


// ======================================================
// LISTAR IMAGENS DOS PRODUTOS
// ======================================================

async function listProductImages({
    nextCursor = null,
    maxResults = 100
} = {}) {

    const params = {
        resource_type: 'image',

        type: 'upload',

        prefix: PRODUCT_IMAGE_FOLDER,

        max_results: Math.min(
            Math.max(Number(maxResults) || 100, 1),
            500
        )
    };


    if (nextCursor) {
        params.next_cursor = nextCursor;
    }


    const result =
        await cloudinary.api.resources(params);


    return result;
}


// ======================================================
// EXCLUIR IMAGEM
// ======================================================

async function deleteProductImage(publicId) {

    if (
        typeof publicId !== 'string' ||
        publicId.trim().length === 0
    ) {
        throw new Error(
            'Public ID da imagem inválido'
        );
    }


    if (
        !publicId.startsWith(
            `${PRODUCT_IMAGE_FOLDER}/`
        )
    ) {
        throw new Error(
            'A imagem não pertence à pasta de produtos'
        );
    }


    const result =
        await cloudinary.api.delete_resources(
            [publicId],

            {
                resource_type: 'image',

                type: 'upload'
            }
        );


    return result;
}


// ======================================================
// CONVERTER URL DO CLOUDINARY EM PUBLIC ID
// ======================================================

function publicIdFromUrl(imageUrl) {

    if (
        typeof imageUrl !== 'string' ||
        imageUrl.trim().length === 0
    ) {
        return null;
    }


    try {

        const parsedUrl =
            new URL(imageUrl);


        const parts =
            parsedUrl.pathname
                .split('/')
                .filter(Boolean);


        const uploadIndex =
            parts.indexOf('upload');


        if (uploadIndex === -1) {
            return null;
        }


        let publicIdParts =
            parts.slice(uploadIndex + 1);


        // --------------------------------------------------
        // REMOVER VERSÃO
        // Exemplo: v1234567890
        // --------------------------------------------------

        if (
            publicIdParts.length > 0 &&
            /^v\d+$/.test(
                publicIdParts[0]
            )
        ) {

            publicIdParts =
                publicIdParts.slice(1);
        }


        if (
            publicIdParts.length === 0
        ) {
            return null;
        }


        // --------------------------------------------------
        // REMOVER EXTENSÃO
        // --------------------------------------------------

        const lastIndex =
            publicIdParts.length - 1;


        const fileName =
            publicIdParts[lastIndex];


        const extensionIndex =
            fileName.lastIndexOf('.');


        if (extensionIndex > 0) {

            publicIdParts[lastIndex] =
                fileName.substring(
                    0,
                    extensionIndex
                );
        }


        const publicId =
            publicIdParts.join('/');


        // --------------------------------------------------
        // GARANTIR QUE PERTENCE À PASTA DE PRODUTOS
        // --------------------------------------------------

        if (
            !publicId.startsWith(
                `${PRODUCT_IMAGE_FOLDER}/`
            )
        ) {
            return null;
        }


        return publicId;

    } catch (error) {

        return null;
    }
}


// ======================================================
// EXCLUIR IMAGEM PELA URL
// ======================================================

async function deleteImageByUrl(imageUrl) {

    const publicId =
        publicIdFromUrl(imageUrl);


    if (!publicId) {

        return {
            deleted: false,
            publicId: null
        };
    }


    const result =
        await deleteProductImage(
            publicId
        );


    return {
        deleted: true,
        publicId,
        result
    };
}


// ======================================================
// CONTAR IMAGENS DOS PRODUTOS
// ======================================================

async function countProductImages() {

    let nextCursor = null;

    let total = 0;


    do {

        const params = {
            resource_type: 'image',

            type: 'upload',

            prefix: PRODUCT_IMAGE_FOLDER,

            max_results: 500
        };


        if (nextCursor) {
            params.next_cursor = nextCursor;
        }


        const result =
            await cloudinary.api.resources(
                params
            );


        total +=
            (result.resources || []).length;


        nextCursor =
            result.next_cursor || null;

    } while (nextCursor);


    return total;
}


// ======================================================
// EXPORTS
// ======================================================

module.exports = {

    uploadImage,

    getUsage,

    listProductImages,

    countProductImages,

    deleteProductImage,

    deleteImageByUrl,

    publicIdFromUrl,

    PRODUCT_IMAGE_FOLDER

};