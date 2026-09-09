import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

class BibliasScreen extends StatefulWidget {
  const BibliasScreen({super.key});

  @override
  State<BibliasScreen> createState() => _BibliasScreenState();
}

class _BibliasScreenState extends State<BibliasScreen> {
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
      appBar: AppBar(title: const Text('Bíblias')),

      body: FutureBuilder<List<ProductModel>>(
        future: products,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final biblias = snapshot.data!
              .where((product) => product.type == 'biblia')
              .toList();

          if (biblias.isEmpty) {
            return const Center(child: Text('Nenhuma bíblia encontrada'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),

            itemCount: biblias.length,

            itemBuilder: (context, index) {
              final product = biblias[index];

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

                  subtitle: Text('Estoque: ${product.stock}'),

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
