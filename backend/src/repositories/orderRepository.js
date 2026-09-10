const pool = require('../config/database');


// ======================================================
// CLIENTE - CRIAR PEDIDO A PARTIR DO CARRINHO
// ======================================================

async function createOrderFromCart(userId) {

    const client = await pool.connect();

    try {

        await client.query('BEGIN');


        const cartResult = await client.query(`
            SELECT
                ci.product_id,
                ci.quantity,
                p.name,
                p.price,
                p.stock,
                p.active
            FROM cart_items ci
            INNER JOIN products p 
                ON p.id = ci.product_id
            WHERE ci.user_id = $1
            FOR UPDATE OF p
        `,[userId]);



        if(cartResult.rows.length === 0){
            throw new Error('Carrinho vazio');
        }



        let total = 0;


        for(const item of cartResult.rows){


            if(!item.active){
                throw new Error(
                    `Produto "${item.name}" não está disponível`
                );
            }


            if(item.quantity > item.stock){

                throw new Error(
                    `Estoque insuficiente para "${item.name}". Disponível: ${item.stock}`
                );

            }


            total += Number(item.price) * Number(item.quantity);

        }



        const userResult = await client.query(`

            SELECT church_id

            FROM users

            WHERE id = $1

            LIMIT 1

        `,[userId]);



        if(userResult.rows.length === 0){

            throw new Error('Usuário não encontrado');

        }



        const churchId = userResult.rows[0].church_id;



        if(!churchId){

            throw new Error(
                'Usuário não possui igreja vinculada'
            );

        }



        // ======================================================
        // CRIA PEDIDO
        // ======================================================


        const orderResult = await client.query(`

            INSERT INTO orders
            (
                user_id,
                church_id,
                total,
                status
            )

            VALUES
            (
                $1,
                $2,
                $3,
                'pending'
            )


            RETURNING
                id,
                user_id,
                church_id,
                total,
                status,
                created_at

        `,[
            userId,
            churchId,
            total
        ]);



        const order = orderResult.rows[0];



        // ======================================================
        // CRIA ENTREGA AUTOMÁTICA
        // ======================================================


        await client.query(`

            INSERT INTO deliveries
            (
                order_id,
                church_id,
                status
            )

            VALUES
            (
                $1,
                $2,
                'pending'
            )

        `,
        [
            order.id,
            churchId
        ]);




        // ======================================================
        // CRIA ITENS DO PEDIDO
        // ======================================================


        for(const item of cartResult.rows){


            const subtotal =
                Number(item.price) *
                Number(item.quantity);



            await client.query(`

                INSERT INTO order_items
                (
                    order_id,
                    product_id,
                    product_name,
                    quantity,
                    unit_price,
                    subtotal
                )


                VALUES
                (
                    $1,
                    $2,
                    $3,
                    $4,
                    $5,
                    $6
                )


            `,
            [
                order.id,
                item.product_id,
                item.name,
                item.quantity,
                item.price,
                subtotal
            ]);

        }


        // ======================================================
        // IMPORTANTE:
        // NÃO DIMINUI O ESTOQUE AQUI
        // NÃO LIMPA O CARRINHO AQUI
        //
        // Isso será feito somente quando o Mercado Pago
        // confirmar o pagamento como "approved".
        // ======================================================



        await client.query('COMMIT');


        return order;



    }catch(error){


        await client.query('ROLLBACK');

        throw error;


    }finally{

        client.release();

    }

}



// ======================================================
// ADMIN - LISTAR TODOS OS PEDIDOS
// ======================================================

async function listAllOrders(){

    const result = await pool.query(`
        SELECT
            o.id,
            o.user_id,

            u.name AS customer_name,
            u.email AS customer_email,
            u.phone AS customer_phone,

            c.name AS church_name,

            o.total,
            o.status,
            o.created_at,
            o.updated_at,

            p.id AS payment_id,
            p.provider AS payment_provider,
            p.provider_payment_id,
            p.status AS payment_status,
            p.amount AS payment_amount,
            p.payment_method,
            p.external_reference

        FROM orders o

        INNER JOIN users u
            ON u.id = o.user_id

        INNER JOIN churches c
            ON c.id = o.church_id

        LEFT JOIN payments p
            ON p.order_id = o.id

        ORDER BY o.created_at DESC
    `);

    return result.rows;
}



// ======================================================
// ADMIN - BUSCAR PEDIDO
// ======================================================

async function findOrderById(orderId){

    const orderResult = await pool.query(`

        SELECT

            o.id,
            o.user_id,
            u.name AS customer_name,
            u.email AS customer_email,
            u.phone AS customer_phone,
            c.name AS church_name,
            o.total,
            o.status,
            o.created_at,
            o.updated_at


        FROM orders o


        INNER JOIN users u

            ON u.id=o.user_id


        INNER JOIN churches c

            ON c.id=o.church_id


        WHERE o.id=$1


    `,
    [
        orderId
    ]);



    if(orderResult.rows.length===0){

        return null;

    }



    const items = await pool.query(`

        SELECT *

        FROM order_items

        WHERE order_id=$1


        ORDER BY id ASC

    `,
    [
        orderId
    ]);



    return {

        ...orderResult.rows[0],

        items:items.rows

    };


}



// ======================================================
// STATUS
// ======================================================

async function updateOrderStatus(orderId,status){

    const result = await pool.query(`

        UPDATE orders

        SET

            status=$1,

            updated_at=CURRENT_TIMESTAMP


        WHERE id=$2


        RETURNING *

    `,
    [
        status,
        orderId
    ]);



    return result.rows[0] || null;

}



// ======================================================
// CLIENTE
// ======================================================

async function listOrdersByUser(userId){

    const result = await pool.query(`
        SELECT
            o.*,
            c.name AS church_name,

            p.id AS payment_id,
            p.provider AS payment_provider,
            p.provider_payment_id,
            p.status AS payment_status,
            p.amount AS payment_amount,
            p.payment_method,
            p.external_reference

        FROM orders o

        INNER JOIN churches c
            ON c.id = o.church_id

        LEFT JOIN payments p
            ON p.order_id = o.id

        WHERE o.user_id = $1

        ORDER BY o.created_at DESC
    `,
    [
        userId
    ]);

    return result.rows;
}




async function findOrderByIdForUser(orderId, userId){

    const result = await pool.query(`
        SELECT
            o.*,
            c.name AS church_name,

            p.id AS payment_id,
            p.provider AS payment_provider,
            p.provider_payment_id,
            p.status AS payment_status,
            p.amount AS payment_amount,
            p.payment_method,
            p.external_reference

        FROM orders o

        INNER JOIN churches c
            ON c.id = o.church_id

        LEFT JOIN payments p
            ON p.order_id = o.id

        WHERE o.id = $1
          AND o.user_id = $2

        LIMIT 1
    `,
    [
        orderId,
        userId
    ]);

    if (result.rows.length === 0) {
        return null;
    }

    const items = await pool.query(`
        SELECT *
        FROM order_items
        WHERE order_id = $1
        ORDER BY id ASC
    `,
    [
        orderId
    ]);

    return {
        ...result.rows[0],
        items: items.rows
    };
}




module.exports={

    createOrderFromCart,

    listAllOrders,

    findOrderById,

    updateOrderStatus,

    listOrdersByUser,

    findOrderByIdForUser

};