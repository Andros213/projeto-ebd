import 'package:flutter/material.dart';

import '../services/cart_service.dart';

import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService cartService = CartService();

  late Future<Map<String, dynamic>> cart;

  @override
  void initState() {
    super.initState();

    cart = cartService.getCart();
  }

  Future<void> reloadCart() async {
    if (!mounted) {
      return;
    }

    setState(() {
      cart = cartService.getCart();
    });

    await cart;
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      await cartService.updateCartItem(
        productId: productId,
        quantity: quantity,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        cart = cartService.getCart();
      });
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

  Future<void> removeItem(int productId) async {
    try {
      await cartService.removeFromCart(productId: productId);

      if (!mounted) {
        return;
      }

      setState(() {
        cart = cartService.getCart();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto removido do carrinho')),
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
    }
  }

  Future<void> openCheckout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );

    if (!mounted) {
      return;
    }

    await reloadCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrinho')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: cart,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};

          final items = data['items'] as List? ?? [];

          final total = NumberUtils.toDouble(data['total']);

          if (items.isEmpty) {
            return const Center(child: Text('Seu carrinho esta vazio'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    final productId =
                        int.tryParse(item['product_id'].toString()) ?? 0;

                    final name = item['name']?.toString() ?? '';

                    final quantity =
                        int.tryParse(item['quantity'].toString()) ?? 0;

                    final price = NumberUtils.toDouble(item['price']);

                    final subtotal = NumberUtils.toDouble(item['subtotal']);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    removeItem(productId);
                                  },
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Remover produto',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Preco: R\$ ${price.toStringAsFixed(2)}'),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: quantity > 1
                                          ? () {
                                              updateQuantity(
                                                productId,
                                                quantity - 1,
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: quantity < 5
                                          ? () {
                                              updateQuantity(
                                                productId,
                                                quantity + 1,
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                                Text(
                                  'R\$ ${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R\$ ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: openCheckout,
                        child: const Text('Ir para o Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NumberUtils {
  static double toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
