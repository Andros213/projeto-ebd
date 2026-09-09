const cloudinaryService =
    require('../services/cloudinaryService');


// ======================================================
// UPLOAD DA FOTO DO PRODUTO
// ======================================================

async function uploadProductImage(
    req,
    res
) {

    try {

        if (!req.file) {

            return res.status(400).json({
                success: false,
                message:
                    'Nenhuma imagem foi enviada'
            });

        }


        const result =
            await cloudinaryService.uploadImage(
                req.file.buffer,
                {
                    folder:
                        'ebd-v2/products'
                }
            );


        return res.status(201).json({

            success: true,

            message:
                'Imagem enviada com sucesso',

            image: {
                url:
                    result.secure_url,

                publicId:
                    result.public_id
            }

        });


    } catch (error) {

        console.error(
            'Erro ao enviar imagem do produto:',
            error
        );


        return res.status(500).json({

            success: false,

            message:
                'Erro interno ao enviar imagem'

        });

    }

}


module.exports = {
    uploadProductImage
};