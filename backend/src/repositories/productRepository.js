const pool = require('../config/database');


// ======================================================
// LISTAR PRODUTOS ATIVOS
// ======================================================

async function findAllActive() {

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

        WHERE active = TRUE

        ORDER BY created_at DESC

    `);


    return result.rows;

}




// ======================================================
// BUSCAR PRODUTO POR ID
// ======================================================

async function findById(id) {


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

        WHERE id = $1

        LIMIT 1

    `,
    [
        id
    ]);


    return result.rows[0] || null;

}




module.exports = {

    findAllActive,

    findById

};