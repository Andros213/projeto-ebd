const productService = require('../services/productService');


// ======================================================
// CADASTRAR PRODUTO
// ======================================================

async function createProduct(req, res) {

    try {

        const {
            name,
            type,
            class: className,
            description,
            price,
            imageUrl,
            stock
        } = req.body;


        if (
            !name ||
            !type ||
            price === undefined ||
            stock === undefined
        ) {

            return res.status(400).json({
                success: false,
                message: 'Nome, tipo, preço e estoque são obrigatórios'
            });

        }



        const product = await productService.createProduct({

            name,

            type,

            className: className || null,

            description: description || null,

            price: Number(price),

            imageUrl: imageUrl || null,

            stock: Number(stock)

        });



        return res.status(201).json({

            success: true,

            message: 'Produto cadastrado com sucesso',

            product

        });



    } catch(error) {


        console.error('Erro ao cadastrar produto:', error);


        return res.status(500).json({

            success:false,

            message:'Erro interno ao cadastrar produto'

        });

    }

}




// ======================================================
// LISTAR PRODUTOS
// ======================================================

async function listAllProducts(req,res){

    try{


        const products = await productService.listAllProducts();


        return res.json({

            success:true,

            products

        });



    }catch(error){


        console.error('Erro ao listar produtos:',error);


        return res.status(500).json({

            success:false,

            message:'Erro interno ao listar produtos'

        });

    }

}




// ======================================================
// ATUALIZAR PRODUTO
// ======================================================

async function updateProduct(req,res){


    try{


        const productId = Number(req.params.id);



        if(!Number.isInteger(productId) || productId <=0){


            return res.status(400).json({

                success:false,

                message:'ID do produto inválido'

            });

        }



        const {

            name,

            type,

            class: className,

            description,

            price,

            imageUrl,

            stock


        } = req.body;




        if(
            !name ||
            !type ||
            price === undefined ||
            stock === undefined
        ){

            return res.status(400).json({

                success:false,

                message:'Nome, tipo, preço e estoque são obrigatórios'

            });

        }




        const product = await productService.updateProduct(

            productId,

            {

                name,

                type,

                className: className || null,

                description: description || null,

                price:Number(price),

                imageUrl:imageUrl || null,

                stock:Number(stock)

            }

        );




        if(!product){


            return res.status(404).json({

                success:false,

                message:'Produto não encontrado'

            });

        }





        return res.json({

            success:true,

            message:'Produto atualizado com sucesso',

            product

        });




    }catch(error){


        console.error('Erro ao atualizar produto:',error);



        return res.status(500).json({

            success:false,

            message:'Erro interno ao atualizar produto'

        });

    }

}




// ======================================================
// ATIVAR / DESATIVAR PRODUTO
// ======================================================

async function setProductActive(req,res){


    try{


        const productId = Number(req.params.id);



        if(!Number.isInteger(productId) || productId <=0){


            return res.status(400).json({

                success:false,

                message:'ID do produto inválido'

            });

        }




        const {active} = req.body;



        if(typeof active !== 'boolean'){


            return res.status(400).json({

                success:false,

                message:'O campo active deve ser true ou false'

            });

        }





        const product = await productService.setProductActive(

            productId,

            active

        );




        if(!product){


            return res.status(404).json({

                success:false,

                message:'Produto não encontrado'

            });

        }





        return res.json({

            success:true,

            message: active

                ? 'Produto ativado com sucesso'

                : 'Produto desativado com sucesso',

            product

        });





    }catch(error){


        console.error('Erro ao alterar status do produto:',error);



        return res.status(500).json({

            success:false,

            message:'Erro interno ao alterar status do produto'

        });

    }

}

// ======================================================
// EXCLUIR PRODUTO
// ======================================================

async function deleteProduct(req, res) {

    try {

        const productId =
            Number(req.params.id);


        if (
            !Number.isInteger(productId) ||
            productId <= 0
        ) {

            return res.status(400).json({

                success: false,

                message: 'ID do produto inválido'

            });

        }


        const result =
            await productService.deleteProduct(
                productId
            );


        // --------------------------------------------------
        // PRODUTO NÃO ENCONTRADO
        // --------------------------------------------------

        if (
            result.reason === 'not_found'
        ) {

            return res.status(404).json({

                success: false,

                message: 'Produto não encontrado'

            });

        }


        // --------------------------------------------------
        // PRODUTO POSSUI HISTÓRICO
        // --------------------------------------------------

        if (
            result.reason === 'has_orders'
        ) {

            return res.status(409).json({

                success: false,

                message:
                    'Este produto já possui pedidos registrados e não pode ser removido. Desative o produto em vez disso.',

                product:
                    result.product

            });

        }


        // --------------------------------------------------
        // EXCLUSÃO
        // --------------------------------------------------

        if (!result.deleted) {

            return res.status(500).json({

                success: false,

                message:
                    'Não foi possível remover o produto'

            });

        }


        return res.json({

            success: true,

            message:
                'Produto removido com sucesso',

            product:
                result.product

        });

    } catch (error) {

        console.error(
            'Erro ao remover produto:',
            error
        );


        return res.status(500).json({

            success: false,

            message:
                'Erro interno ao remover produto'

        });

    }
}


module.exports = {
    createProduct,
    listAllProducts,
    updateProduct,
    setProductActive,
    deleteProduct
};