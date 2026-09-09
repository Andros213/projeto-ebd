import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

class RevistasScreen extends StatefulWidget {
  const RevistasScreen({super.key});

  @override
  State<RevistasScreen> createState() => _RevistasScreenState();
}

class _RevistasScreenState extends State<RevistasScreen> {
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
      appBar: AppBar(title: const Text('Revistas EBD')),

      body: FutureBuilder<List<ProductModel>>(
        future: products,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final revistas = (snapshot.data ?? [])
              .where((product) => product.type == 'revista')
              .toList();

          if (revistas.isEmpty) {
            return const Center(child: Text('Nenhuma revista encontrada'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),

            itemCount: revistas.length,

            itemBuilder: (context, index) {
              final product = revistas[index];

              return Card(
                child: ListTile(
                  title: Text(product.name),

                  subtitle: Text('Estoque: ${product.stock}'),

                  trailing: Text('R\$ ${product.price.toStringAsFixed(2)}'),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
