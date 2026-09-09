const cloudinaryService =
    require('../services/cloudinaryService');

const productService =
    require('../services/productService');


// ======================================================
// RESUMO DO CLOUDINARY
// ======================================================

async function getCloudinarySummary(req, res) {

    try {

        const [
            usage,
            imageCount
        ] = await Promise.all([
            cloudinaryService.getUsage(),
            cloudinaryService.countProductImages()
        ]);


        const storage =
            usage?.storage || {};


        return res.json({

            success: true,

            cloudinary: {

                storage: {

                    used:
                        Number(
                            storage.usage || 0
                        ),

                    limit:
                        Number(
                            storage.limit || 0
                        ),

                    available:
                        Number(storage.limit || 0) > 0
                            ? Math.max(
                                Number(storage.limit) -
                                Number(storage.usage || 0),
                                0
                            )
                            : null
                },


                images: {

                    count:
                        imageCount

                },


                credits:
                    usage?.credits || null,


                bandwidth:
                    usage?.bandwidth || null,


                requests:
                    Number(
                        usage?.requests || 0
                    )
            }

        });

    } catch (error) {

        console.error(
            'Erro ao consultar uso do Cloudinary:',
            error
        );


        return res.status(500).json({

            success: false,

            message:
                'Erro interno ao consultar o Cloudinary'

        });
    }
}


// ======================================================
// LISTAR IMAGENS
// ======================================================

async function listCloudinaryImages(req, res) {

    try {

        const nextCursor =
            req.query.nextCursor || null;


        const maxResults =
            Number(
                req.query.maxResults || 100
            );


        const cloudinaryResult =
            await cloudinaryService.listProductImages({
                nextCursor,
                maxResults
            });


        const products =
            await productService.listAllProducts();


        const productImageMap =
            new Map();


        for (const product of products) {

            const imageUrl =
                product.image_url?.toString().trim();


            if (
                !imageUrl
            ) {
                continue;
            }


            if (
                !productImageMap.has(imageUrl)
            ) {

                productImageMap.set(
                    imageUrl,
                    []
                );
            }


            productImageMap
                .get(imageUrl)
                .push({
                    id: product.id,
                    name: product.name
                });
        }


        const images =
            (cloudinaryResult.resources || [])
                .map((resource) => {

                    const secureUrl =
                        resource.secure_url ||
                        null;


                    const linkedProducts =
                        secureUrl
                            ? (
                                productImageMap.get(
                                    secureUrl
                                ) || []
                            )
                            : [];


                    return {

                        publicId:
                            resource.public_id,

                        assetId:
                            resource.asset_id,

                        secureUrl,

                        bytes:
                            Number(
                                resource.bytes || 0
                            ),

                        format:
                            resource.format || null,

                        width:
                            Number(
                                resource.width || 0
                            ),

                        height:
                            Number(
                                resource.height || 0
                            ),

                        createdAt:
                            resource.created_at ||
                            null,

                        resourceType:
                            resource.resource_type ||
                            'image',

                        type:
                            resource.type ||
                            'upload',

                        used:
                            linkedProducts.length > 0,

                        products:
                            linkedProducts
                    };
                });


        return res.json({

            success: true,

            images,

            nextCursor:
                cloudinaryResult.next_cursor ||
                null

        });

    } catch (error) {

        console.error(
            'Erro ao listar imagens do Cloudinary:',
            error
        );


        return res.status(500).json({

            success: false,

            message:
                'Erro interno ao listar imagens'

        });
    }
}


// ======================================================
// EXCLUIR IMAGEM
// ======================================================

async function deleteCloudinaryImage(req, res) {

    try {

        const {
            publicId
        } = req.body;


        if (
            typeof publicId !== 'string' ||
            publicId.trim().length === 0
        ) {

            return res.status(400).json({

                success: false,

                message:
                    'Public ID da imagem é obrigatório'

            });
        }


        const normalizedPublicId =
            publicId.trim();


        // --------------------------------------------------
        // CONFIRMAR QUE A IMAGEM REALMENTE EXISTE
        // --------------------------------------------------

        const cloudinaryResult =
            await cloudinaryService.listProductImages({
                maxResults: 500
            });


        const resource =
            (
                cloudinaryResult.resources ||
                []
            )
                .find(
                    (item) =>
                        item.public_id ===
                        normalizedPublicId
                );


        if (!resource) {

            return res.status(404).json({

                success: false,

                message:
                    'Imagem não encontrada na pasta de produtos'

            });
        }


        // --------------------------------------------------
        // VERIFICAR SE ESTÁ SENDO USADA POR PRODUTO
        // --------------------------------------------------

        const products =
            await productService.listAllProducts();


        const linkedProducts =
            products.filter((product) => {

                const imageUrl =
                    product.image_url
                        ?.toString()
                        .trim();


                return (
                    imageUrl &&
                    imageUrl ===
                        resource.secure_url
                );
            });


        if (
            linkedProducts.length > 0
        ) {

            return res.status(409).json({

                success: false,

                message:
                    'Esta imagem está vinculada a um produto e não pode ser excluída.',

                products:
                    linkedProducts.map(
                        (product) => ({

                            id: product.id,

                            name: product.name

                        })
                    )
            });
        }


        // --------------------------------------------------
        // EXCLUIR
        // --------------------------------------------------

        const result =
            await cloudinaryService.deleteProductImage(
                normalizedPublicId
            );


        return res.json({

            success: true,

            message:
                'Imagem excluída com sucesso',

            publicId:
                normalizedPublicId,

            result

        });

    } catch (error) {

        console.error(
            'Erro ao excluir imagem do Cloudinary:',
            error
        );


        return res.status(500).json({

            success: false,

            message:
                'Erro interno ao excluir imagem'

        });
    }
}


module.exports = {

    getCloudinarySummary,

    listCloudinaryImages,

    deleteCloudinaryImage

};