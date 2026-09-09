import 'package:flutter/material.dart';

import '../services/admin_product_service.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final AdminProductService adminProductService = AdminProductService();

  late Future<List<Map<String, dynamic>>> productsFuture;

  @override
  void initState() {
    super.initState();

    productsFuture = adminProductService.listAllProducts();
  }

  Future<void> reloadProducts() async {
    setState(() {
      productsFuture = adminProductService.listAllProducts();
    });

    await productsFuture;
  }

  String formatMoney(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;

    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ==========================================================
  // ATIVAR / DESATIVAR
  // ==========================================================

  Future<void> changeProductActive(Map<String, dynamic> product) async {
    final productId = int.parse(product['id'].toString());

    final currentActive = product['active'] == true;

    final newActive = !currentActive;

    try {
      await adminProductService.setProductActive(
        productId: productId,
        active: newActive,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newActive
                ? 'Produto ativado com sucesso'
                : 'Produto desativado com sucesso',
          ),
        ),
      );

      await reloadProducts();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ==========================================================
  // REMOVER PRODUTO
  // ==========================================================

  Future<void> confirmDeleteProduct(Map<String, dynamic> product) async {
    final productId = int.parse(product['id'].toString());

    final productName = product['name']?.toString() ?? 'Produto';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover produto?'),
          content: Text(
            'O produto "$productName" será removido permanentemente. '
            'A imagem também poderá ser removida do Cloudinary caso não seja utilizada por outro produto.\n\n'
            'Essa ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await adminProductService.deleteProduct(productId: productId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produto "$productName" removido com sucesso.')),
      );

      await reloadProducts();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: reloadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
          );

          if (result == true) {
            await reloadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: productsFuture,
        builder: (context, snapshot) {
          // ==================================================
          // CARREGANDO
          // ==================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ==================================================
          // ERRO
          // ==================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),

                    const SizedBox(height: 16),

                    Text(
                      snapshot.error?.toString() ?? 'Erro ao carregar produtos',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: reloadProducts,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          // ==================================================
          // VAZIO
          // ==================================================

          if (products.isEmpty) {
            return RefreshIndicator(
              onRefresh: reloadProducts,
              child: ListView(
                children: const [
                  SizedBox(height: 180),

                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum produto cadastrado.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ==================================================
          // LISTA
          // ==================================================

          return RefreshIndicator(
            onRefresh: reloadProducts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: products.length,

              itemBuilder: (context, index) {
                final product = products[index];

                final productId = product['id'];

                final name = product['name'] ?? 'Produto';

                final type = product['type'] ?? 'Não informado';

                final price = product['price'];

                final stock = product['stock'] ?? 0;

                final active = product['active'] == true;

                final imageUrl = product['image_url'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // ========================================
                        // CABEÇALHO
                        // ========================================
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            // IMAGEM
                            if (imageUrl != null &&
                                imageUrl.toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),

                                child: Image.network(
                                  imageUrl.toString(),

                                  width: 70,
                                  height: 70,

                                  fit: BoxFit.cover,

                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 70,
                                      height: 70,

                                      alignment: Alignment.center,

                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade200,
                                      ),

                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: 70,
                                height: 70,

                                alignment: Alignment.center,

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),

                                child: const Icon(Icons.image),
                              ),

                            const SizedBox(width: 12),

                            // NOME / TIPO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    name.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text('Categoria: ${type.toString()}'),

                                  const SizedBox(height: 5),

                                  Text('ID: $productId'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ========================================
                        // PREÇO
                        // ========================================
                        Text(
                          formatMoney(price),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ========================================
                        // ESTOQUE
                        // ========================================
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 20),

                            const SizedBox(width: 8),

                            Text('Estoque: $stock'),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ========================================
                        // STATUS
                        // ========================================
                        Row(
                          children: [
                            Icon(
                              active ? Icons.check_circle : Icons.cancel,

                              size: 20,

                              color: active ? Colors.green : Colors.red,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              active ? 'Ativo' : 'Inativo',

                              style: TextStyle(
                                fontWeight: FontWeight.bold,

                                color: active ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ========================================
                        // EDITAR
                        // ========================================
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminProductFormScreen(product: product),
                                ),
                              );

                              if (result == true) {
                                await reloadProducts();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ========================================
                        // ATIVAR / DESATIVAR
                        // ========================================
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              changeProductActive(product);
                            },

                            icon: Icon(
                              active ? Icons.visibility_off : Icons.visibility,
                            ),

                            label: Text(active ? 'Desativar' : 'Ativar'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ========================================
                        // REMOVER
                        // ========================================
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              confirmDeleteProduct(product);
                            },

                            icon: const Icon(Icons.delete_outline),

                            label: const Text('Remover produto'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
