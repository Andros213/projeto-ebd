import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/admin_product_service.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final AdminProductService adminProductService = AdminProductService();

  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController typeController = TextEditingController();

  final TextEditingController classController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController priceController = TextEditingController();

  final TextEditingController stockController = TextEditingController();

  Uint8List? selectedImageBytes;
  String? selectedImageName;
  String? uploadedImageUrl;

  bool selectingImage = false;
  bool uploadingImage = false;
  bool saving = false;

  bool get editing => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    if (product != null) {
      nameController.text = product['name']?.toString() ?? '';

      typeController.text = product['type']?.toString() ?? '';

      classController.text = product['class']?.toString() ?? '';

      descriptionController.text = product['description']?.toString() ?? '';

      priceController.text = product['price']?.toString() ?? '';

      stockController.text = product['stock']?.toString() ?? '';

      uploadedImageUrl = product['image_url']?.toString();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    classController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();

    super.dispose();
  }

  // ==========================================================
  // ESCOLHER IMAGEM
  // ==========================================================

  Future<void> pickImage({required ImageSource source}) async {
    if (selectingImage || uploadingImage || saving) {
      return;
    }

    setState(() {
      selectingImage = true;
    });

    try {
      final XFile? file = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        selectedImageBytes = bytes;
        selectedImageName = file.name;
        uploadedImageUrl = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          selectingImage = false;
        });
      }
    }
  }

  // ==========================================================
  // REMOVER FOTO SELECIONADA
  // ==========================================================

  void removeSelectedImage() {
    if (saving) {
      return;
    }

    setState(() {
      selectedImageBytes = null;
      selectedImageName = null;
      uploadedImageUrl = null;
    });
  }

  // ==========================================================
  // VALIDAR CAMPOS
  // ==========================================================

  String? validateFields() {
    if (nameController.text.trim().isEmpty) {
      return 'Informe o nome do produto.';
    }

    if (typeController.text.trim().isEmpty) {
      return 'Informe o tipo/categoria do produto.';
    }

    final price = double.tryParse(
      priceController.text.trim().replaceAll(',', '.'),
    );

    if (price == null || price < 0) {
      return 'Informe um preço válido.';
    }

    final stock = int.tryParse(stockController.text.trim());

    if (stock == null || stock < 0) {
      return 'Informe um estoque válido.';
    }

    return null;
  }

  // ==========================================================
  // SALVAR PRODUTO
  // ==========================================================

  Future<void> saveProduct() async {
    if (saving) {
      return;
    }

    final validationError = validateFields();

    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));

      return;
    }

    setState(() {
      saving = true;
    });

    try {
      // ================================================
      // DADOS
      // ================================================

      final name = nameController.text.trim();

      final type = typeController.text.trim();

      final className = classController.text.trim();

      final description = descriptionController.text.trim();

      final price = double.parse(
        priceController.text.trim().replaceAll(',', '.'),
      );

      final stock = int.parse(stockController.text.trim());

      // ================================================
      // UPLOAD DA FOTO
      // ================================================

      if (selectedImageBytes != null) {
        setState(() {
          uploadingImage = true;
        });

        try {
          final result = await adminProductService.uploadProductImage(
            bytes: selectedImageBytes!.toList(),

            fileName: selectedImageName ?? 'produto.jpg',
          );

          uploadedImageUrl = result['url']?.toString();

          if (uploadedImageUrl == null || uploadedImageUrl!.isEmpty) {
            throw Exception('O servidor não retornou a URL da imagem.');
          }
        } finally {
          if (mounted) {
            setState(() {
              uploadingImage = false;
            });
          }
        }
      }

      // ================================================
      // CRIAR OU ATUALIZAR
      // ================================================

      if (editing) {
        final productId = int.parse(widget.product!['id'].toString());

        await adminProductService.updateProduct(
          productId: productId,

          name: name,

          type: type,

          className: className.isEmpty ? null : className,

          description: description.isEmpty ? null : description,

          price: price,

          imageUrl: uploadedImageUrl,

          stock: stock,
        );
      } else {
        await adminProductService.createProduct(
          name: name,

          type: type,

          className: className.isEmpty ? null : className,

          description: description.isEmpty ? null : description,

          price: price,

          imageUrl: uploadedImageUrl,

          stock: stock,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing
                ? 'Produto atualizado com sucesso.'
                : 'Produto cadastrado com sucesso.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
          uploadingImage = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(icon),

      border: const OutlineInputBorder(),
    );
  }

  // ==========================================================
  // ÁREA DA FOTO
  // ==========================================================

  Widget buildImageSection() {
    Widget preview;

    if (selectedImageBytes != null) {
      preview = Image.memory(
        selectedImageBytes!,
        width: double.infinity,
        height: 240,
        fit: BoxFit.contain,
      );
    } else if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty) {
      preview = Image.network(
        uploadedImageUrl!,

        width: double.infinity,
        height: 240,

        fit: BoxFit.contain,

        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.image_not_supported, size: 70));
        },
      );
    } else {
      preview = Container(
        width: double.infinity,
        height: 240,

        alignment: Alignment.center,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),

          color: Colors.grey.shade100,

          border: Border.all(color: Colors.grey.shade300),
        ),

        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 60),

            SizedBox(height: 10),

            Text('Nenhuma foto selecionada'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Foto do produto',

          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(12),

          child: Container(
            width: double.infinity,

            height: 240,

            color: Colors.grey.shade100,

            child: preview,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: selectingImage || saving
                    ? null
                    : () => pickImage(source: ImageSource.camera),

                icon: const Icon(Icons.camera_alt),

                label: const Text('Tirar foto'),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: selectingImage || saving
                    ? null
                    : () => pickImage(source: ImageSource.gallery),

                icon: const Icon(Icons.photo_library),

                label: const Text('Escolher foto'),
              ),
            ),
          ],
        ),

        if (selectedImageBytes != null) ...[
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,

            child: TextButton.icon(
              onPressed: saving ? null : removeSelectedImage,

              icon: const Icon(Icons.delete_outline),

              label: const Text('Remover foto'),
            ),
          ),
        ],

        if (uploadingImage) ...[
          const SizedBox(height: 10),

          const LinearProgressIndicator(),

          const SizedBox(height: 6),

          const Text('Enviando foto...'),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = saving || selectingImage || uploadingImage;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar produto' : 'Novo produto')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // FOTO
            // ==================================================
            buildImageSection(),

            const SizedBox(height: 24),

            // ==================================================
            // NOME
            // ==================================================
            TextField(
              controller: nameController,

              enabled: !isProcessing,

              textInputAction: TextInputAction.next,

              decoration: fieldDecoration(
                'Nome do produto',
                Icons.inventory_2_outlined,
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TIPO / CATEGORIA
            // ==================================================
            DropdownButtonFormField<String>(
              value: typeController.text.isEmpty ? null : typeController.text,

              decoration: fieldDecoration(
                'Tipo / Categoria',
                Icons.category_outlined,
              ),

              items: const [
                DropdownMenuItem<String>(
                  value: 'revista',
                  child: Text('Revista'),
                ),

                DropdownMenuItem<String>(value: 'livro', child: Text('Livro')),

                DropdownMenuItem<String>(value: 'outro', child: Text('Outro')),
              ],

              onChanged: isProcessing
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        typeController.text = value;
                      });
                    },
            ),

            const SizedBox(height: 16),

            // ==================================================
            // CLASSE
            // ==================================================
            TextField(
              controller: classController,

              enabled: !isProcessing,

              textInputAction: TextInputAction.next,

              decoration: fieldDecoration('Classe', Icons.menu_book_outlined),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // DESCRIÇÃO
            // ==================================================
            TextField(
              controller: descriptionController,

              enabled: !isProcessing,

              minLines: 4,

              maxLines: 8,

              decoration: fieldDecoration(
                'Descrição',
                Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PREÇO
            // ==================================================
            TextField(
              controller: priceController,

              enabled: !isProcessing,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              textInputAction: TextInputAction.next,

              decoration: fieldDecoration('Preço', Icons.attach_money),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // ESTOQUE
            // ==================================================
            TextField(
              controller: stockController,

              enabled: !isProcessing,

              keyboardType: TextInputType.number,

              textInputAction: TextInputAction.done,

              decoration: fieldDecoration('Estoque', Icons.inventory_outlined),

              onSubmitted: (_) => saveProduct(),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // SALVAR
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 52,

              child: ElevatedButton(
                onPressed: isProcessing ? null : saveProduct,

                child: isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,

                        child: CircularProgressIndicator(),
                      )
                    : Text(editing ? 'Salvar alterações' : 'Cadastrar produto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
