const multer = require('multer');


// ======================================================
// ARMAZENAMENTO EM MEMÓRIA
// ======================================================

const storage =
    multer.memoryStorage();


// ======================================================
// FILTRO DE ARQUIVO
// ======================================================

function fileFilter(
    req,
    file,
    callback
) {

    if (
        file.mimetype &&
        file.mimetype.startsWith('image/')
    ) {

        callback(
            null,
            true
        );

        return;
    }


    callback(
        new Error(
            'Apenas arquivos de imagem são permitidos'
        )
    );

}


// ======================================================
// UPLOAD
// ======================================================

const upload =
    multer({
        storage,

        limits: {
            fileSize:
                5 * 1024 * 1024
        },

        fileFilter
    });


module.exports = upload;