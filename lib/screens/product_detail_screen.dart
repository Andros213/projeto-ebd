import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService cartService = CartService();

  bool addingToCart = false;
  bool buyingNow = false;

  // ==========================================================
  // ADICIONAR AO CARRINHO
  // ==========================================================

  Future<void> addToCart() async {
    if (addingToCart || buyingNow) {
      return;
    }

    setState(() {
      addingToCart = true;
    });

    try {
      await cartService.addToCart(productId: widget.product.id, quantity: 1);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto adicionado ao carrinho')),
      );
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
          addingToCart = false;
        });
      }
    }
  }

  // ==========================================================
  // COMPRAR AGORA
  // ==========================================================

  Future<void> buyNow() async {
    if (addingToCart || buyingNow) {
      return;
    }

    setState(() {
      buyingNow = true;
    });

    try {
      await cartService.addToCart(productId: widget.product.id, quantity: 1);

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
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
          buyingNow = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final isProcessing = addingToCart || buyingNow;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do produto')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGEM
            // ==================================================
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              Center(
                child: Image.network(
                  product.imageUrl!,

                  height: 280,

                  fit: BoxFit.contain,

                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 280,

                      child: Center(
                        child: Icon(Icons.image_not_supported, size: 80),
                      ),
                    );
                  },
                ),
              )
            else
              const Center(
                child: SizedBox(
                  height: 280,

                  child: Center(child: Icon(Icons.image, size: 80)),
                ),
              ),

            const SizedBox(height: 30),

            // ==================================================
            // NOME
            // ==================================================
            Text(
              product.name,

              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // CATEGORIA
            // ==================================================
            Text(
              'Categoria: ${product.type}',

              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // DESCRIÇÃO
            // ==================================================
            if (product.description != null && product.description!.isNotEmpty)
              Text(product.description!, style: const TextStyle(fontSize: 17)),

            const SizedBox(height: 25),

            // ==================================================
            // PREÇO
            // ==================================================
            Text(
              'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}',

              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ESTOQUE
            // ==================================================
            Text(
              'Estoque disponível: ${product.stock}',

              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // BOTÃO COMPRAR AGORA
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed: product.stock > 0 && !isProcessing ? buyNow : null,

                child: buyingNow
                    ? const SizedBox(
                        width: 24,
                        height: 24,

                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        product.stock > 0
                            ? 'Comprar agora'
                            : 'Produto sem estoque',
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // BOTÃO ADICIONAR AO CARRINHO
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 50,

              child: OutlinedButton(
                onPressed: product.stock > 0 && !isProcessing
                    ? addToCart
                    : null,

                child: addingToCart
                    ? const SizedBox(
                        width: 24,
                        height: 24,

                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        product.stock > 0
                            ? 'Adicionar ao carrinho'
                            : 'Produto sem estoque',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
