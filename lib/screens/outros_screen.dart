import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

class OutrosScreen extends StatefulWidget {
  const OutrosScreen({super.key});

  @override
  State<OutrosScreen> createState() => _OutrosScreenState();
}

class _OutrosScreenState extends State<OutrosScreen> {
  final ProductService service = ProductService();

  late Future<List<ProductModel>> products;

  @override
  void initState() {
    super.initState();
    products = service.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Livros e Outros')),
      body: FutureBuilder<List<ProductModel>>(
        future: products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final outros = snapshot.data!
              .where(
                (product) =>
                    product.type != 'revista' && product.type != 'biblia',
              )
              .toList();

          if (outros.isEmpty) {
            return const Center(
              child: Text('Nenhum livro ou outro produto encontrado'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: outros.length,
            itemBuilder: (context, index) {
              final product = outros[index];

              return Card(
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  title: Text(product.name),
                  subtitle: Text(
                    'Tipo: ${product.type} | Estoque: ${product.stock}',
                  ),
                  trailing: Text('R\$ ${product.price.toStringAsFixed(2)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
