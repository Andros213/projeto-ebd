import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/mercado_pago_config.dart';
import '../services/cart_service.dart';
import '../services/mercado_pago_web.dart';
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
  bool paymentBrickReady = false;
  bool waitingPayment = false;
  bool paymentMonitoringFinished = false;

  int? waitingOrderId;

  String paymentMessage = 'Aguardando confirmação do pagamento...';

  String? preferenceId;

  String? pixQrCode;
  String? pixQrCodeBase64;
  String? pixTicketUrl;

  @override
  void initState() {
    super.initState();

    registerPaymentBrickView();

    cart = cartService.getCart();
  }

  Future<void> initializePaymentBrick({
    required double amount,
    required String preferenceIdValue,
  }) async {
    try {
      await initializeMercadoPago(MercadoPagoConfig.publicKey);

      await renderPaymentBrick(
        amount: amount,
        preferenceId: preferenceIdValue,
        onSubmit: processBrickPayment,
        onReady: () {
          if (!mounted) {
            return;
          }

          setState(() {
            paymentBrickReady = true;
          });
        },
        onError: (error) {
          if (!mounted) {
            return;
          }

          setState(() {
            paymentBrickReady = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro no formulário de pagamento: $error')),
          );
        },
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

  Future<void> processBrickPayment(String formDataJson) async {
    if (processing) {
      return;
    }

    final orderId = waitingOrderId;

    if (orderId == null) {
      throw Exception('Pedido não encontrado.');
    }

    if (mounted) {
      setState(() {
        processing = true;
        paymentMessage = 'Processando pagamento...';
      });
    }

    try {
      final decoded = jsonDecode(formDataJson);

      if (decoded is! Map) {
        throw Exception('Dados de pagamento inválidos.');
      }

      final paymentData = Map<String, dynamic>.from(decoded);

      final result = await paymentService.processPayment(
        orderId: orderId,
        paymentData: paymentData,
      );

      final payment = result['payment'] is Map
          ? Map<String, dynamic>.from(result['payment'])
          : <String, dynamic>{};

      final status = payment['status']?.toString().toLowerCase();

      // O backend retorna "pix" no nível principal da resposta,
      // e não dentro de "payment".
      final pix = payment['pix'] is Map
          ? Map<String, dynamic>.from(payment['pix'])
          : null;

      if (mounted) {
        setState(() {
          pixQrCode = pix?['qr_code']?.toString();
          pixQrCodeBase64 = pix?['qr_code_base64']?.toString();
          pixTicketUrl = pix?['ticket_url']?.toString();

          paymentMessage =
              'Pagamento enviado ao Mercado Pago.\n\n'
              'Aguardando confirmação...';
        });
      }

      if (status == 'approved') {
        await handleApprovedPayment(orderId);
        return;
      }

      unawaited(monitorPayment(orderId));
    } catch (error) {
      if (mounted) {
        setState(() {
          paymentMessage = 'Não foi possível processar o pagamento.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          processing = false;
        });
      }
    }
  }

  Future<void> confirmPurchase() async {
    if (processing || waitingPayment) {
      return;
    }

    setState(() {
      processing = true;
    });

    try {
      // 1. Cria o pedido pendente.
      final order = await orderService.createOrder();

      final orderId = int.tryParse(order['id'].toString());

      if (orderId == null) {
        throw Exception('ID do pedido não recebido.');
      }

      // 2. Cria a Preference do Mercado Pago.
      final preference = await paymentService.createPreference(
        orderId: orderId,
      );

      final preferenceValue = preference['id']?.toString();

      if (preferenceValue == null || preferenceValue.isEmpty) {
        throw Exception('ID da Preference não recebido.');
      }

      // 3. Recupera o total atual do carrinho.
      final cartData = await cartService.getCart();

      final total = NumberUtils.toDouble(cartData['total']);

      if (total <= 0) {
        throw Exception('Valor do pedido inválido.');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        waitingOrderId = orderId;
        preferenceId = preferenceValue;
        paymentBrickReady = false;
        paymentMonitoringFinished = false;
        waitingPayment = false;

        pixQrCode = null;
        pixQrCodeBase64 = null;
        pixTicketUrl = null;

        paymentMessage =
            'Pedido #$orderId criado.\n\n'
            'Escolha a forma de pagamento abaixo.';
      });

      // Aguarda o Flutter colocar o HtmlElementView no DOM.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        initializePaymentBrick(
          amount: total,
          preferenceIdValue: preferenceValue,
        );
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
    } finally {
      if (mounted) {
        setState(() {
          processing = false;
        });
      }
    }
  }

  Future<void> handleApprovedPayment(int orderId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      waitingPayment = false;
      paymentMonitoringFinished = true;

      paymentMessage =
          'Pagamento aprovado!\n\n'
          'Seu pedido foi confirmado.';
    });

    destroyPaymentBrick();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }

  Future<void> monitorPayment(int orderId) async {
    const int maxAttempts = 100;

    if (waitingPayment) {
      return;
    }

    if (mounted) {
      setState(() {
        waitingPayment = true;
        paymentMonitoringFinished = false;
      });
    }

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (!mounted || waitingOrderId != orderId) {
        return;
      }

      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 3));
      }

      if (!mounted || waitingOrderId != orderId) {
        return;
      }

      try {
        final order = await orderService.getMyOrderById(orderId);

        final paymentStatus = order['payment_status']?.toString().toLowerCase();

        if (paymentStatus == 'approved') {
          await handleApprovedPayment(orderId);
          return;
        }

        if (paymentStatus == 'rejected') {
          if (!mounted) {
            return;
          }

          setState(() {
            paymentMonitoringFinished = true;
            waitingPayment = false;

            paymentMessage =
                'O pagamento do pedido #$orderId '
                'foi recusado.\n\n'
                'Você pode tentar novamente.';
          });

          return;
        }

        if (paymentStatus == 'cancelled') {
          if (!mounted) {
            return;
          }

          setState(() {
            paymentMonitoringFinished = true;
            waitingPayment = false;

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
              'Pagamento enviado.\n\n'
              'Aguardando confirmação do Mercado Pago...';
        });
      } catch (_) {
        // Erro temporário de consulta.
        // Continua tentando.
      }
    }

    if (!mounted || waitingOrderId != orderId) {
      return;
    }

    setState(() {
      paymentMonitoringFinished = true;
      waitingPayment = false;

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

  Future<void> copyPixCode() async {
    final code = pixQrCode;

    if (code == null || code.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código Pix copiado.')));
  }

  Widget buildPixData() {
    final hasBase64 = pixQrCodeBase64 != null && pixQrCodeBase64!.isNotEmpty;

    final hasQrCode = pixQrCode != null && pixQrCode!.isNotEmpty;

    if (!hasBase64 && !hasQrCode) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pagamento via Pix',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            if (hasBase64)
              Builder(
                builder: (context) {
                  try {
                    final imageBytes = base64Decode(pixQrCodeBase64!);

                    return Center(
                      child: Image.memory(
                        imageBytes,
                        width: 260,
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                },
              ),

            if (hasQrCode) ...[
              const SizedBox(height: 16),

              const Text(
                'Código Pix copia e cola:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  pixQrCode!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: copyPixCode,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código Pix'),
                ),
              ),
            ],

            if (pixTicketUrl != null && pixTicketUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),

              SelectableText(
                pixTicketUrl!,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildPaymentBrickState() {
    final orderId = waitingOrderId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    orderId == null ? 'Pagamento' : 'Pedido #$orderId',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    paymentMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  if (!paymentBrickReady && !waitingPayment)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Mantemos os 900px para o Payment Brick.
                  const SizedBox(
                    height: 900,
                    child: HtmlElementView(viewType: paymentBrickViewType),
                  ),

                  buildPixData(),

                  if (waitingPayment) ...[
                    const SizedBox(height: 16),

                    const Center(child: CircularProgressIndicator()),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: openOrderDetails,
                      child: const Text('Ver pedido'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        destroyPaymentBrick();

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
  void dispose() {
    destroyPaymentBrick();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPayment = waitingOrderId != null && preferenceId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: hasPayment
          ? buildPaymentBrickState()
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

                                  Text(
                                    'Quantidade: '
                                    '$quantity',
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    'Preco unitario: '
                                    'R\$ '
                                    '${price.toStringAsFixed(2)}',
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    'Subtotal: '
                                    'R\$ '
                                    '${subtotal.toStringAsFixed(2)}',
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
                                'R\$ '
                                '${total.toStringAsFixed(2)}',
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
                                  : const Text('Continuar para pagamento'),
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
