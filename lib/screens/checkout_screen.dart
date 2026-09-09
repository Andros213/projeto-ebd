import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService cartService = CartService();

  final OrderService orderService = OrderService();

  final PaymentService paymentService = PaymentService();

  late Future<Map<String, dynamic>> cart;

  bool processing = false;

  bool waitingPayment = false;

  bool paymentMonitoringFinished = false;

  int? waitingOrderId;

  String paymentMessage = 'Aguardando confirmação do pagamento...';

  @override
  void initState() {
    super.initState();

    cart = cartService.getCart();
  }

  Future<void> confirmPurchase() async {
    if (processing || waitingPayment) {
      return;
    }

    setState(() {
      processing = true;
    });

    try {
      // 1. Cria o pedido no backend.
      final order = await orderService.createOrder();

      final orderId = int.tryParse(order['id'].toString());

      if (orderId == null) {
        throw Exception('ID do pedido não recebido');
      }

      // 2. Cria a Preference do Mercado Pago.
      final preference = await paymentService.createPreference(
        orderId: orderId,
      );

      final sandboxUrl = preference['sandboxInitPoint']?.toString();

      final productionUrl = preference['initPoint']?.toString();

      // Durante os testes, usamos o sandbox.
      final paymentUrl = sandboxUrl != null && sandboxUrl.isNotEmpty
          ? sandboxUrl
          : productionUrl;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('Link de pagamento não recebido');
      }

      final uri = Uri.tryParse(paymentUrl);

      if (uri == null) {
        throw Exception('Link de pagamento inválido');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Não foi possível abrir o Mercado Pago');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        waitingPayment = true;
        paymentMonitoringFinished = false;
        waitingOrderId = orderId;
        paymentMessage =
            'Pedido #$orderId criado.\n\n'
            'O Mercado Pago foi aberto em outra janela. '
            'Estamos aguardando a confirmação do pagamento.';
      });

      // 3. Começa a acompanhar automaticamente
      // o status do pagamento.
      unawaited(monitorPayment(orderId));
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
          processing = false;
        });
      }
    }
  }

  Future<void> monitorPayment(int orderId) async {
    const int maxAttempts = 100;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (!mounted || !waitingPayment || waitingOrderId != orderId) {
        return;
      }

      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 3));
      }

      if (!mounted || !waitingPayment || waitingOrderId != orderId) {
        return;
      }

      try {
        final order = await orderService.getMyOrderById(orderId);

        final paymentStatus = order['payment_status']?.toString().toLowerCase();

        if (paymentStatus == 'approved') {
          if (!mounted) {
            return;
          }

          setState(() {
            waitingPayment = false;
            paymentMonitoringFinished = true;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: orderId),
            ),
          );

          return;
        }

        if (paymentStatus == 'rejected') {
          if (!mounted) {
            return;
          }

          setState(() {
            paymentMonitoringFinished = true;
            paymentMessage =
                'O pagamento do pedido #$orderId '
                'foi recusado.\n\n'
                'O pedido continua aguardando processamento.';
          });

          return;
        }

        if (paymentStatus == 'cancelled') {
          if (!mounted) {
            return;
          }

          setState(() {
            paymentMonitoringFinished = true;
            paymentMessage =
                'O pagamento do pedido #$orderId '
                'foi cancelado.';
          });

          return;
        }

        if (!mounted) {
          return;
        }

        setState(() {
          paymentMessage =
              'Pedido #$orderId criado.\n\n'
              'Aguardando confirmação do Mercado Pago...';
        });
      } catch (_) {
        // Mantém a tentativa de consulta.
        // Um erro temporário da API não cancela o pedido.
      }
    }

    if (!mounted || !waitingPayment || waitingOrderId != orderId) {
      return;
    }

    setState(() {
      paymentMonitoringFinished = true;
      paymentMessage =
          'Ainda não recebemos a confirmação '
          'do pagamento do pedido #$orderId.\n\n'
          'O pedido continua salvo e você pode '
          'consultá-lo em Minhas compras.';
    });
  }

  Future<void> openOrderDetails() async {
    final orderId = waitingOrderId;

    if (orderId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }

  Widget buildPaymentWaitingState() {
    final orderId = waitingOrderId;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (!paymentMonitoringFinished)
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(),
                    )
                  else
                    const Icon(Icons.info_outline, size: 48),

                  const SizedBox(height: 20),

                  Text(
                    orderId == null ? 'Pagamento' : 'Pedido #$orderId',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    paymentMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: openOrderDetails,
                      child: const Text('Ver pedido'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Voltar ao carrinho'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: waitingPayment
          ? buildPaymentWaitingState()
          : FutureBuilder<Map<String, dynamic>>(
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
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          final name = item['name']?.toString() ?? '';

                          final quantity =
                              int.tryParse(item['quantity'].toString()) ?? 0;

                          final price = NumberUtils.toDouble(item['price']);

                          final subtotal = NumberUtils.toDouble(
                            item['subtotal'],
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Quantidade: $quantity'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Preco unitario: '
                                    'R\$ ${price.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Subtotal: '
                                    'R\$ ${subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
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
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: processing ? null : confirmPurchase,
                              child: processing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Text('Pagar com Mercado Pago'),
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
