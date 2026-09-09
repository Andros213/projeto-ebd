import 'package:flutter/material.dart';

import '../services/admin_order_service.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminOrderService adminOrderService = AdminOrderService();

  late Future<List<Map<String, dynamic>>> ordersFuture;

  @override
  void initState() {
    super.initState();

    ordersFuture = adminOrderService.listAllOrders();
  }

  Future<void> reloadOrders() async {
    setState(() {
      ordersFuture = adminOrderService.listAllOrders();
    });

    await ordersFuture;
  }

  String getOrderStatusText(dynamic status) {
    switch (status?.toString()) {
      case 'pending':
        return 'Aguardando processamento';

      case 'confirmed':
        return 'Confirmado';

      case 'preparing':
        return 'Preparando';

      case 'shipped':
        return 'Enviado';

      case 'delivered':
        return 'Entregue';

      case 'cancelled':
        return 'Cancelado';

      default:
        return 'Desconhecido';
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
        title: const Text('Pedidos'),

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
                        'Nenhum pedido encontrado.',
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

                final customerName = order['customer_name'] ?? 'Cliente';

                final churchName =
                    order['church_name'] ?? 'Igreja não informada';

                final paymentColor = getPaymentStatusColor(paymentStatus);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),

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

                        const SizedBox(height: 12),

                        Text('Cliente: $customerName'),

                        const SizedBox(height: 6),

                        Text('Igreja: $churchName'),

                        const SizedBox(height: 10),

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

                            const Text('Status: '),

                            Expanded(
                              child: Text(getOrderStatusText(orderStatus)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,

                          child: OutlinedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminOrderDetailScreen(
                                    orderId: int.parse(orderId.toString()),
                                  ),
                                ),
                              );

                              await reloadOrders();
                            },

                            child: const Text('Abrir pedido'),
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
