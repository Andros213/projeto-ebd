import 'package:flutter/material.dart';

import '../services/admin_order_service.dart';


class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}


class _AdminOrderDetailScreenState
    extends State<AdminOrderDetailScreen> {

  final AdminOrderService adminOrderService =
      AdminOrderService();

  late Future<Map<String, dynamic>> orderFuture;

  bool updatingStatus = false;


  @override
  void initState() {
    super.initState();

    orderFuture =
        adminOrderService.getOrderById(
      widget.orderId,
    );
  }


  Future<void> reloadOrder() async {
    setState(() {
      orderFuture =
          adminOrderService.getOrderById(
        widget.orderId,
      );
    });

    await orderFuture;
  }


  String getOrderStatusText(
    dynamic status,
  ) {
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


  String getPaymentStatusText(
    dynamic status,
  ) {
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


  Color getPaymentStatusColor(
    dynamic status,
  ) {
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
    final amount =
        double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }


  List<String> getAvailableNextStatuses(
    String? currentStatus,
  ) {
    switch (currentStatus) {
      case 'pending':
        return [
          'confirmed',
          'cancelled',
        ];

      case 'confirmed':
        return [
          'preparing',
          'cancelled',
        ];

      case 'preparing':
        return [
          'shipped',
          'cancelled',
        ];

      case 'shipped':
        return [
          'delivered',
        ];

      default:
        return [];
    }
  }


  Future<void> changeStatus(
    String newStatus,
  ) async {
    if (updatingStatus) {
      return;
    }

    setState(() {
      updatingStatus = true;
    });

    try {
      await adminOrderService.updateOrderStatus(
        orderId: widget.orderId,
        status: newStatus,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status alterado para "${getOrderStatusText(newStatus)}"',
          ),
        ),
      );

      await reloadOrder();

    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          updatingStatus = false;
        });
      }
    }
  }


  Future<void> confirmStatusChange(
    String newStatus,
  ) async {
    final statusText =
        getOrderStatusText(newStatus);

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Alterar status',
          ),

          content: Text(
            'Deseja alterar o pedido para "$statusText"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
                  const Text(
                'Cancelar',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'Confirmar',
              ),
            ),
          ],
        );
      },
    );


    if (confirmed == true) {
      await changeStatus(
        newStatus,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pedido #${widget.orderId}',
        ),

        actions: [
          IconButton(
            tooltip: 'Atualizar',

            onPressed:
                updatingStatus
                    ? null
                    : reloadOrder,

            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: FutureBuilder<
          Map<String, dynamic>>(
        future: orderFuture,

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }


          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Text(
                      snapshot.error
                              ?.toString() ??
                          'Erro ao carregar pedido',

                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    ElevatedButton(
                      onPressed:
                          reloadOrder,

                      child:
                          const Text(
                        'Tentar novamente',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }


          final order =
              snapshot.data;


          if (order == null) {
            return const Center(
              child:
                  Text(
                'Pedido não encontrado.',
              ),
            );
          }


          final orderId =
              order['id'];

          final customerName =
              order['customer_name'] ??
                  'Cliente não informado';

          final customerEmail =
              order['customer_email'] ??
                  'Não informado';

          final customerPhone =
              order['customer_phone'] ??
                  'Não informado';

          final churchName =
              order['church_name'] ??
                  'Igreja não informada';

          final total =
              order['total'];

          final orderStatus =
              order['status']?.toString();

          final paymentStatus =
              order['payment_status'];

          final paymentMethod =
              order['payment_method'];

          final providerPaymentId =
              order['provider_payment_id'];

          final items =
              (order['items'] as List?)
                  ?.map(
                    (item) =>
                        Map<String, dynamic>.from(
                      item,
                    ),
                  )
                  .toList() ??
              [];


          final availableStatuses =
              getAvailableNextStatuses(
            orderStatus,
          );


          final paymentColor =
              getPaymentStatusColor(
            paymentStatus,
          );


          return RefreshIndicator(
            onRefresh:
                reloadOrder,

            child: ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Pedido #$orderId',

                          style:
                              const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        const Text(
                          'Cliente',

                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          customerName,
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          customerEmail,
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          customerPhone,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            const Icon(
                              Icons.church,
                              size: 22,
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  Text(
                                churchName,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Pagamento',

                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons.payment,
                              size: 22,
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Text(
                              'Status: ',
                            ),

                            Text(
                              getPaymentStatusText(
                                paymentStatus,
                              ),

                              style:
                                  TextStyle(
                                color:
                                    paymentColor,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        if (paymentMethod != null)
                          const SizedBox(
                            height: 8,
                          ),

                        if (paymentMethod != null)
                          Text(
                            'Método: $paymentMethod',
                          ),

                        if (providerPaymentId !=
                            null)
                          const SizedBox(
                            height: 8,
                          ),

                        if (providerPaymentId !=
                            null)
                          Text(
                            'ID Mercado Pago: $providerPaymentId',
                          ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          'Valor: ${formatMoney(order['payment_amount'] ?? total)}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Produtos',

                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(16),

                      child: Text(
                        'Nenhum item encontrado.',
                      ),
                    ),
                  ),

                ...items.map(
                  (item) {
                    final productName =
                        item['product_name'] ??
                            'Produto';

                    final quantity =
                        item['quantity'] ??
                            0;

                    final unitPrice =
                        item['unit_price'];

                    final subtotal =
                        item['subtotal'];

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              productName
                                  .toString(),

                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              '$quantity × ${formatMoney(unitPrice)}',
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              'Subtotal: ${formatMoney(subtotal)}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 4,
                ),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [
                        const Text(
                          'Total',

                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          formatMoney(total),

                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Status do pedido',

                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          getOrderStatusText(
                            orderStatus,
                          ),

                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        if (updatingStatus)
                          const Padding(
                            padding:
                                EdgeInsets.only(
                              top: 16,
                            ),

                            child:
                                LinearProgressIndicator(),
                          ),

                        if (availableStatuses
                            .isNotEmpty)
                          const SizedBox(
                            height: 16,
                          ),

                        ...availableStatuses.map(
                          (nextStatus) {
                            final isCancel =
                                nextStatus ==
                                    'cancelled';

                            return SizedBox(
                              width:
                                  double.infinity,

                              child:
                                  Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  bottom: 8,
                                ),

                                child:
                                    OutlinedButton(
                                  onPressed:
                                      updatingStatus
                                          ? null
                                          : () {
                                              confirmStatusChange(
                                                nextStatus,
                                              );
                                            },

                                  child: Text(
                                    isCancel
                                        ? 'Cancelar pedido'
                                        : 'Alterar para ${getOrderStatusText(nextStatus)}',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        if (availableStatuses
                            .isEmpty)
                          const Padding(
                            padding:
                                EdgeInsets.only(
                              top: 12,
                            ),

                            child: Text(
                              'Nenhuma alteração de status disponível.',
                            ),
                          ),
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