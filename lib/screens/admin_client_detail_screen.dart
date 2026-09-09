import 'package:flutter/material.dart';

import '../services/admin_user_service.dart';


class AdminClientDetailScreen
    extends StatefulWidget {

  final int clientId;


  const AdminClientDetailScreen({
    super.key,
    required this.clientId,
  });


  @override
  State<AdminClientDetailScreen> createState() =>
      _AdminClientDetailScreenState();
}


class _AdminClientDetailScreenState
    extends State<AdminClientDetailScreen> {

  final AdminUserService adminUserService =
      AdminUserService();


  late Future<Map<String, dynamic>>
      clientFuture;


  @override
  void initState() {
    super.initState();

    clientFuture =
        adminUserService.getClientById(
      widget.clientId,
    );
  }


  Future<void> reloadClient() async {
    setState(() {
      clientFuture =
          adminUserService.getClientById(
        widget.clientId,
      );
    });

    await clientFuture;
  }


  String formatMoney(dynamic value) {

    final amount =
        double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;


    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }


  String orderStatusText(
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


  Color orderStatusColor(
    dynamic status,
  ) {

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


  String paymentStatusText(
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


  Color paymentStatusColor(
    dynamic status,
  ) {

    switch (status?.toString()) {

      case 'approved':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'rejected':
      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Cliente',
        ),

        actions: [

          IconButton(
            tooltip:
                'Atualizar',

            onPressed:
                reloadClient,

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
            clientFuture,

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
                      snapshot.error
                              ?.toString() ??
                          'Erro ao carregar cliente',

                      textAlign:
                          TextAlign.center,
                    ),


                    const SizedBox(
                      height: 16,
                    ),


                    ElevatedButton(
                      onPressed:
                          reloadClient,

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


          final client =
              snapshot.data;


          if (client == null) {

            return const Center(
              child:
                  Text(
                'Cliente não encontrado.',
              ),
            );
          }


          final name =
              client['name'] ??
                  'Cliente';


          final email =
              client['email'] ??
                  'Não informado';


          final phone =
              client['phone'] ??
                  'Não informado';


          final churchName =
              client['church_name'] ??
                  'Igreja não informada';


          final active =
              client['active'] == true;


          final orders =
              (client['orders'] as List?)
                  ?.map(
                    (order) =>
                        Map<String, dynamic>.from(
                      order,
                    ),
                  )
                  .toList() ??
              [];


          return RefreshIndicator(
            onRefresh:
                reloadClient,

            child:
                ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [

                // ==================================================
                // DADOS
                // ==================================================

                Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Row(
                          children: [

                            const CircleAvatar(
                              radius: 28,

                              child:
                                  Icon(
                                Icons.person,
                                size: 30,
                              ),
                            ),


                            const SizedBox(
                              width: 14,
                            ),


                            Expanded(
                              child:
                                  Text(
                                name.toString(),

                                style:
                                    const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),


                            Icon(
                              active
                                  ? Icons
                                      .check_circle
                                  : Icons
                                      .cancel,

                              color:
                                  active
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ],
                        ),


                        const SizedBox(
                          height: 20,
                        ),


                        Text(
                          'E-mail: ${email.toString()}',
                        ),


                        const SizedBox(
                          height: 8,
                        ),


                        Text(
                          'Telefone: ${phone.toString()}',
                        ),


                        const SizedBox(
                          height: 8,
                        ),


                        Text(
                          'Igreja: ${churchName.toString()}',
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(
                  height: 16,
                ),


                // ==================================================
                // PEDIDOS
                // ==================================================

                Text(
                  'Histórico de pedidos',

                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),


                const SizedBox(
                  height: 12,
                ),


                if (orders.isEmpty)

                  const Card(
                    child:
                        Padding(
                      padding:
                          EdgeInsets.all(16),

                      child:
                          Text(
                        'Este cliente ainda não possui pedidos.',
                      ),
                    ),
                  )


                else

                  ...orders.map(
                    (order) {

                      final orderId =
                          order['id'];


                      final total =
                          order['total'];


                      final orderStatus =
                          order['status'];


                      final paymentStatus =
                          order['payment_status'];


                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),

                        child:
                            Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),

                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,

                                children: [

                                  Text(
                                    'Pedido #$orderId',

                                    style:
                                        const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),


                                  Text(
                                    formatMoney(
                                      total,
                                    ),

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),


                              const SizedBox(
                                height: 10,
                              ),


                              Row(
                                children: [

                                  const Text(
                                    'Pagamento: ',
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
                                height: 6,
                              ),


                              Row(
                                children: [

                                  const Text(
                                    'Pedido: ',
                                  ),


                                  Text(
                                    orderStatusText(
                                      orderStatus,
                                    ),

                                    style:
                                        TextStyle(
                                      color:
                                          orderStatusColor(
                                        orderStatus,
                                      ),

                                      fontWeight:
                                          FontWeight.bold,
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
              ],
            ),
          );
        },
      ),
    );
  }
}