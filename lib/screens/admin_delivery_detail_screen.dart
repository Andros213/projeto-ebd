import 'package:flutter/material.dart';

import '../services/admin_delivery_service.dart';


class AdminDeliveryDetailScreen
    extends StatefulWidget {

  final int deliveryId;


  const AdminDeliveryDetailScreen({
    super.key,
    required this.deliveryId,
  });


  @override
  State<AdminDeliveryDetailScreen> createState() =>
      _AdminDeliveryDetailScreenState();
}


class _AdminDeliveryDetailScreenState
    extends State<AdminDeliveryDetailScreen> {

  final AdminDeliveryService adminDeliveryService =
      AdminDeliveryService();


  late Future<Map<String, dynamic>>
      deliveryFuture;


  bool updatingStatus = false;


  @override
  void initState() {
    super.initState();

    deliveryFuture =
        adminDeliveryService.getDeliveryById(
      widget.deliveryId,
    );
  }


  Future<void> reloadDelivery() async {
    setState(() {
      deliveryFuture =
          adminDeliveryService.getDeliveryById(
        widget.deliveryId,
      );
    });

    await deliveryFuture;
  }


  String statusText(dynamic status) {

    switch (status?.toString()) {

      case 'pending':
        return 'Pendente';

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


  Color statusColor(dynamic status) {

    switch (status?.toString()) {

      case 'confirmed':
        return Colors.blue;

      case 'preparing':
        return Colors.orange;

      case 'shipped':
        return Colors.deepPurple;

      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }


  String paymentStatusText(dynamic status) {

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


  Color paymentStatusColor(dynamic status) {

    switch (status?.toString()) {

      case 'approved':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'rejected':
      case 'cancelled':
        return Colors.red;

      case 'refunded':
        return Colors.deepPurple;

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


  List<String> availableStatuses(
    String? status,
  ) {

    switch (status) {

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


  Future<void> updateStatus(
    String newStatus,
  ) async {

    if (updatingStatus) {
      return;
    }


    setState(() {
      updatingStatus = true;
    });


    try {

      await adminDeliveryService
          .updateDeliveryStatus(
        deliveryId:
            widget.deliveryId,

        status:
            newStatus,
      );


      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(
            'Entrega atualizada para "${statusText(newStatus)}"',
          ),
        ),
      );


      await reloadDelivery();


    } catch (error) {

      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(
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

    final confirmed =
        await showDialog<bool>(
      context:
          context,

      builder:
          (dialogContext) {

        return AlertDialog(

          title:
              const Text(
            'Alterar entrega',
          ),

          content:
              Text(
            'Deseja alterar o status para "${statusText(newStatus)}"?',
          ),

          actions: [

            TextButton(
              onPressed:
                  () {
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
              onPressed:
                  () {
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

      await updateStatus(
        newStatus,
      );
    }
  }


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar:
          AppBar(
        title:
            const Text(
          'Detalhes da entrega',
        ),

        actions: [

          IconButton(
            tooltip:
                'Atualizar',

            onPressed:
                updatingStatus
                    ? null
                    : reloadDelivery,

            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),


      body:
          FutureBuilder<
              Map<String, dynamic>>(
        future:
            deliveryFuture,

        builder:
            (
          context,
          snapshot,
        ) {

          if (
            snapshot.connectionState ==
                ConnectionState.waiting
          ) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }


          if (snapshot.hasError) {

            return Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),

                child:
                    Column(
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
                      snapshot.error?.toString() ??
                          'Erro ao carregar entrega',

                      textAlign:
                          TextAlign.center,
                    ),


                    const SizedBox(
                      height: 16,
                    ),


                    ElevatedButton(
                      onPressed:
                          reloadDelivery,

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


          final delivery =
              snapshot.data;


          if (delivery == null) {

            return const Center(
              child:
                  Text(
                'Entrega não encontrada.',
              ),
            );
          }


          final orderId =
              delivery['order_id'];


          final customerName =
              delivery['customer_name'] ??
                  'Cliente não informado';


          final customerEmail =
              delivery['customer_email'] ??
                  'Não informado';


          final customerPhone =
              delivery['customer_phone'] ??
                  'Não informado';


          final churchName =
              delivery['church_name'] ??
                  'Igreja não informada';


          final total =
              delivery['order_total'];


          final paymentStatus =
              delivery['payment_status'];


          final currentStatus =
              delivery['status']?.toString();


          final notes =
              delivery['notes'];


          final deliveredAt =
              delivery['delivered_at'];


          final nextStatuses =
              availableStatuses(
            currentStatus,
          );


          return RefreshIndicator(
            onRefresh:
                reloadDelivery,

            child:
                ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [

                // ==================================================
                // PEDIDO
                // ==================================================

                Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

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


                        Text(
                          'Cliente: ${customerName.toString()}',
                        ),


                        const SizedBox(
                          height: 7,
                        ),


                        Text(
                          'E-mail: ${customerEmail.toString()}',
                        ),


                        const SizedBox(
                          height: 7,
                        ),


                        Text(
                          'Telefone: ${customerPhone.toString()}',
                        ),


                        const SizedBox(
                          height: 12,
                        ),


                        Row(
                          children: [

                            const Icon(
                              Icons.church,
                              size: 20,
                            ),


                            const SizedBox(
                              width: 8,
                            ),


                            Expanded(
                              child:
                                  Text(
                                churchName.toString(),
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


                // ==================================================
                // PAGAMENTO
                // ==================================================

                Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

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
                            ),


                            const SizedBox(
                              width: 8,
                            ),


                            const Text(
                              'Status: ',
                            ),


                            Text(
                              paymentStatusText(
                                paymentStatus,
                              ),

                              style:
                                  TextStyle(
                                color:
                                    paymentStatusColor(
                                  paymentStatus,
                                ),

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),


                        const SizedBox(
                          height: 10,
                        ),


                        Text(
                          'Valor do pedido: ${formatMoney(total)}',
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(
                  height: 16,
                ),


                // ==================================================
                // ENTREGA
                // ==================================================

                Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        const Text(
                          'Entrega',

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

                            Icon(
                              Icons.local_shipping,

                              color:
                                  statusColor(
                                currentStatus,
                              ),
                            ),


                            const SizedBox(
                              width: 8,
                            ),


                            Text(
                              statusText(
                                currentStatus,
                              ),

                              style:
                                  TextStyle(
                                color:
                                    statusColor(
                                  currentStatus,
                                ),

                                fontWeight:
                                    FontWeight.bold,

                                fontSize:
                                    17,
                              ),
                            ),
                          ],
                        ),


                        if (notes != null &&
                            notes.toString()
                                .trim()
                                .isNotEmpty) ...[

                          const SizedBox(
                            height: 12,
                          ),


                          Text(
                            'Observações: ${notes.toString()}',
                          ),
                        ],


                        if (deliveredAt != null) ...[

                          const SizedBox(
                            height: 12,
                          ),


                          Text(
                            'Entregue em: ${deliveredAt.toString()}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),


                const SizedBox(
                  height: 16,
                ),


                // ==================================================
                // ALTERAR STATUS
                // ==================================================

                Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        const Text(
                          'Alterar status',

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


                        if (updatingStatus)
                          const LinearProgressIndicator(),


                        if (updatingStatus)
                          const SizedBox(
                            height: 12,
                          ),


                        if (nextStatuses.isEmpty)

                          const Text(
                            'Nenhuma alteração de status disponível.',
                          )

                        else

                          ...nextStatuses.map(
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

                                    child:
                                        Text(
                                      isCancel
                                          ? 'Cancelar entrega'
                                          : 'Alterar para ${statusText(nextStatus)}',
                                    ),
                                  ),
                                ),
                              );
                            },
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