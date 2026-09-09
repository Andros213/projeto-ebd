import 'package:flutter/material.dart';

import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService orderService = OrderService();

  late Future<List<Map<String, dynamic>>> ordersFuture;

  @override
  void initState() {
    super.initState();

    ordersFuture = orderService.listMyOrders();
  }

  Future<void> reloadOrders() async {
    setState(() {
      ordersFuture = orderService.listMyOrders();
    });

    await ordersFuture;
  }

  String getOrderStatusText(dynamic status) {
    switch (status?.toString()) {
      case 'pending':
        return 'Aguardando processamento';

      case 'confirmed':
        return 'Pedido confirmado';

      case 'preparing':
        return 'Preparando pedido';

      case 'shipped':
        return 'Pedido enviado';

      case 'delivered':
        return 'Pedido entregue';

      case 'cancelled':
        return 'Pedido cancelado';

      default:
        return 'Status desconhecido';
    }
  }

  String getPaymentStatusText(dynamic status) {
    switch (status?.toString()) {
      case 'approved':
        return 'Aprovado';

      case 'pending':
        return 'Pendente';

      case 'rejected':
        return 'Recusado';

      case 'cancelled':
        return 'Cancelado';

      case 'refunded':
        return 'Estornado';

      default:
        return 'Não informado';
    }
  }

  Color getPaymentStatusColor(dynamic status) {
    switch (status?.toString()) {
      case 'approved':
        return Colors.green;

      case 'rejected':
      case 'cancelled':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  String formatMoney(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;

    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas compras'),

        actions: [
          IconButton(
            tooltip: 'Atualizar',

            onPressed: reloadOrders,

            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ordersFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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
                      snapshot.error?.toString() ?? 'Erro ao carregar pedidos',

                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: reloadOrders,

                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: reloadOrders,

              child: ListView(
                children: const [
                  SizedBox(height: 180),

                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),

                      child: Text(
                        'Você ainda não possui compras.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: reloadOrders,

            child: ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: orders.length,

              itemBuilder: (context, index) {
                final order = orders[index];

                final orderId = order['id'];

                final total = order['total'];

                final orderStatus = order['status'];

                final paymentStatus = order['payment_status'];

                final paymentColor = getPaymentStatusColor(paymentStatus);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),

                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),

                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                            orderId: int.parse(orderId.toString()),
                          ),
                        ),
                      );

                      await reloadOrders();
                    },

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              Text(
                                'Pedido #$orderId',

                                style: const TextStyle(
                                  fontSize: 18,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                formatMoney(total),

                                style: const TextStyle(
                                  fontSize: 17,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              const Icon(Icons.payment, size: 20),

                              const SizedBox(width: 8),

                              const Text('Pagamento: '),

                              Text(
                                getPaymentStatusText(paymentStatus),

                                style: TextStyle(
                                  color: paymentColor,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(Icons.local_shipping, size: 20),

                              const SizedBox(width: 8),

                              const Text('Pedido: '),

                              Expanded(
                                child: Text(getOrderStatusText(orderStatus)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          const Align(
                            alignment: Alignment.centerRight,

                            child: Text(
                              'Ver detalhes →',

                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
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
