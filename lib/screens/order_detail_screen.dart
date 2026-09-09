import 'package:flutter/material.dart';

import '../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService orderService = OrderService();

  late Future<Map<String, dynamic>> orderFuture;

  @override
  void initState() {
    super.initState();

    orderFuture = orderService.getMyOrderById(widget.orderId);
  }

  Future<void> reloadOrder() async {
    setState(() {
      orderFuture = orderService.getMyOrderById(widget.orderId);
    });

    await orderFuture;
  }

  // ==========================================================
  // STATUS DO PEDIDO
  // ==========================================================

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

  // ==========================================================
  // STATUS DO PAGAMENTO
  // ==========================================================

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

  // ==========================================================
  // FORMATAÇÃO DE VALOR
  // ==========================================================

  String formatMoney(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;

    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ==========================================================
  // ETAPA DA LINHA DE ACOMPANHAMENTO
  // ==========================================================

  Widget buildProgressStep({
    required String title,
    required String subtitle,
    required bool completed,
    required bool current,
    required bool last,
  }) {
    final Color activeColor = completed || current
        ? Colors.green
        : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),

              child: Icon(
                completed
                    ? Icons.check
                    : current
                    ? Icons.local_shipping
                    : Icons.circle_outlined,

                color: Colors.white,
                size: 19,
              ),
            ),

            if (!last) Container(width: 3, height: 50, color: activeColor),
          ],
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: TextStyle(
                    fontSize: 16,

                    fontWeight: completed || current
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 4),

                Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ACOMPANHAMENTO DO PEDIDO
  // ==========================================================

  Widget buildOrderTracking(String? status, bool paymentApproved) {
    const steps = ['confirmed', 'preparing', 'shipped', 'delivered'];

    final currentIndex = steps.indexOf(status ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Acompanhamento do pedido',

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PAGAMENTO
            // ==================================================
            buildProgressStep(
              title: 'Pagamento aprovado',

              subtitle: paymentApproved
                  ? 'Pagamento confirmado pelo Mercado Pago'
                  : 'Aguardando confirmação do pagamento',

              completed: paymentApproved,

              current: false,

              last: false,
            ),

            // ==================================================
            // PEDIDO CONFIRMADO
            // ==================================================
            buildProgressStep(
              title: 'Pedido confirmado',

              subtitle: 'Seu pedido foi confirmado',

              completed: currentIndex >= 0,

              current: currentIndex == 0,

              last: false,
            ),

            // ==================================================
            // PREPARANDO
            // ==================================================
            buildProgressStep(
              title: 'Preparando pedido',

              subtitle: 'Seu pedido está sendo preparado',

              completed: currentIndex >= 1,

              current: currentIndex == 1,

              last: false,
            ),

            // ==================================================
            // ENVIADO
            // ==================================================
            buildProgressStep(
              title: 'Pedido enviado',

              subtitle: 'Seu pedido foi enviado',

              completed: currentIndex >= 3,

              current: currentIndex == 2,

              last: false,
            ),

            // ==================================================
            // ENTREGUE
            // ==================================================
            buildProgressStep(
              title: 'Pedido entregue',

              subtitle: 'Pedido entregue com sucesso',

              completed: currentIndex >= 3,

              current: currentIndex == 3,

              last: true,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TELA
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.orderId}'),

        actions: [
          IconButton(
            tooltip: 'Atualizar',

            onPressed: reloadOrder,

            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: orderFuture,

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
                      snapshot.error?.toString() ?? 'Erro ao carregar pedido',

                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: reloadOrder,

                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ==================================================
          // PEDIDO
          // ==================================================

          final order = snapshot.data;

          if (order == null) {
            return const Center(child: Text('Pedido não encontrado'));
          }

          final orderId = order['id'];

          final total = order['total'];

          final orderStatus = order['status']?.toString();

          final paymentStatus = order['payment_status'];

          final paymentColor = getPaymentStatusColor(paymentStatus);

          final paymentApproved = paymentStatus?.toString() == 'approved';

          // ==================================================
          // PRODUTOS
          // ==================================================

          final items =
              (order['items'] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              [];

          // ==================================================
          // TELA
          // ==================================================

          return RefreshIndicator(
            onRefresh: reloadOrder,

            child: ListView(
              padding: const EdgeInsets.all(16),

              children: [
                // ==================================================
                // RESUMO DO PEDIDO
                // ==================================================
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Pedido #$orderId',

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // PAGAMENTO
                        Row(
                          children: [
                            const Icon(Icons.payment, size: 22),

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

                        const SizedBox(height: 10),

                        // ENTREGA
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 22),

                            const SizedBox(width: 8),

                            const Text('Entrega: '),

                            Expanded(
                              child: Text(getOrderStatusText(orderStatus)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // IGREJA
                        if (order['church_name'] != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Icon(Icons.church, size: 22),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text('Igreja: ${order['church_name']}'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // ACOMPANHAMENTO
                // ==================================================
                const SizedBox(height: 16),

                buildOrderTracking(orderStatus, paymentApproved),

                // ==================================================
                // PRODUTOS
                // ==================================================
                const SizedBox(height: 16),

                const Text(
                  'Produtos',

                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),

                      child: Text('Nenhum item encontrado.'),
                    ),
                  ),

                ...items.map((item) {
                  final name = item['product_name'] ?? 'Produto';

                  final quantity = item['quantity'] ?? 0;

                  final unitPrice = item['unit_price'];

                  final subtotal = item['subtotal'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            name.toString(),

                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text('$quantity × ${formatMoney(unitPrice)}'),

                          const SizedBox(height: 4),

                          Text('Subtotal: ${formatMoney(subtotal)}'),
                        ],
                      ),
                    ),
                  );
                }),

                // ==================================================
                // TOTAL
                // ==================================================
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Row(
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
                          formatMoney(total),

                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // INFORMAÇÕES DO PAGAMENTO
                // ==================================================
                if (paymentStatus != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Informações do pagamento',

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Status: ${getPaymentStatusText(paymentStatus)}',
                          ),

                          if (order['payment_method'] != null)
                            const SizedBox(height: 6),

                          if (order['payment_method'] != null)
                            Text('Método: ${order['payment_method']}'),

                          if (order['provider_payment_id'] != null)
                            const SizedBox(height: 6),

                          if (order['provider_payment_id'] != null)
                            Text('Pagamento: ${order['provider_payment_id']}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
