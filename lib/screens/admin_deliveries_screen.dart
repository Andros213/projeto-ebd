import 'package:flutter/material.dart';

import '../services/admin_delivery_service.dart';
import 'admin_delivery_detail_screen.dart';


class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({
    super.key,
  });

  @override
  State<AdminDeliveriesScreen> createState() =>
      _AdminDeliveriesScreenState();
}


class _AdminDeliveriesScreenState
    extends State<AdminDeliveriesScreen> {

  final AdminDeliveryService adminDeliveryService =
      AdminDeliveryService();


  late Future<List<Map<String, dynamic>>>
      deliveriesFuture;


  String search = '';
  String selectedStatus = 'all';


  @override
  void initState() {
    super.initState();

    deliveriesFuture =
        adminDeliveryService.listDeliveries();
  }


  Future<void> reloadDeliveries() async {
    setState(() {
      deliveriesFuture =
          adminDeliveryService.listDeliveries();
    });

    await deliveriesFuture;
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


  List<Map<String, dynamic>> filterDeliveries(
    List<Map<String, dynamic>> deliveries,
  ) {

    final query =
        search.trim().toLowerCase();


    return deliveries.where(
      (delivery) {

        final status =
            delivery['status']?.toString() ??
                '';


        if (
          selectedStatus != 'all' &&
          status != selectedStatus
        ) {
          return false;
        }


        if (query.isEmpty) {
          return true;
        }


        final orderId =
            delivery['order_id']
                    ?.toString()
                    .toLowerCase() ??
                '';


        final customerName =
            delivery['customer_name']
                    ?.toString()
                    .toLowerCase() ??
                '';


        final phone =
            delivery['customer_phone']
                    ?.toString()
                    .toLowerCase() ??
                '';


        final churchName =
            delivery['church_name']
                    ?.toString()
                    .toLowerCase() ??
                '';


        return orderId.contains(query) ||
            customerName.contains(query) ||
            phone.contains(query) ||
            churchName.contains(query);
      },
    ).toList();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Entregas',
        ),

        actions: [

          IconButton(
            tooltip:
                'Atualizar',

            onPressed:
                reloadDeliveries,

            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),


      body:
          FutureBuilder<
              List<Map<String, dynamic>>>(
        future:
            deliveriesFuture,

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
                          'Erro ao carregar entregas',

                      textAlign:
                          TextAlign.center,
                    ),


                    const SizedBox(
                      height: 16,
                    ),


                    ElevatedButton(
                      onPressed:
                          reloadDeliveries,

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


          final deliveries =
              snapshot.data ?? [];


          final filtered =
              filterDeliveries(
            deliveries,
          );


          return RefreshIndicator(
            onRefresh:
                reloadDeliveries,

            child:
                ListView(
              padding:
                  const EdgeInsets.all(
                16,
              ),

              children: [

                // ==================================================
                // PESQUISA
                // ==================================================

                TextField(
                  onChanged:
                      (value) {

                    setState(() {
                      search = value;
                    });
                  },

                  decoration:
                      InputDecoration(
                    labelText:
                        'Pesquisar entrega',

                    hintText:
                        'Pedido, cliente, telefone ou igreja',

                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),

                    suffixIcon:
                        search.isNotEmpty
                            ? IconButton(
                                onPressed:
                                    () {
                                  setState(() {
                                    search = '';
                                  });
                                },

                                icon:
                                    const Icon(
                                  Icons.clear,
                                ),
                              )
                            : null,

                    border:
                        const OutlineInputBorder(),
                  ),
                ),


                const SizedBox(
                  height: 12,
                ),


                // ==================================================
                // FILTRO
                // ==================================================

                DropdownButtonFormField<String>(
                  initialValue:
                      selectedStatus,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Status da entrega',

                    border:
                        OutlineInputBorder(),
                  ),

                  items: const [

                    DropdownMenuItem(
                      value:
                          'all',

                      child:
                          Text(
                        'Todos',
                      ),
                    ),


                    DropdownMenuItem(
                      value:
                          'pending',

                      child:
                          Text(
                        'Pendentes',
                      ),
                    ),


                    DropdownMenuItem(
                      value:
                          'confirmed',

                      child:
                          Text(
                        'Confirmados',
                      ),
                    ),


                    DropdownMenuItem(
                      value:
                          'preparing',

                      child:
                          Text(
                        'Preparando',
                      ),
                    ),


                    DropdownMenuItem(
                      value:
                          'shipped',

                      child:
                          Text(
                        'Enviados',
                      ),
                    ),


                    DropdownMenuItem(
                      value:
                          'delivered',

                      child:
                          Text(
                        'Entregues',
                      ),
                    ),


                    DropdownMenuItem(
                      value:
                          'cancelled',

                      child:
                          Text(
                        'Cancelados',
                      ),
                    ),
                  ],

                  onChanged:
                      (value) {

                    if (value == null) {
                      return;
                    }


                    setState(() {
                      selectedStatus = value;
                    });
                  },
                ),


                const SizedBox(
                  height: 20,
                ),


                Text(
                  '${filtered.length} entrega(s)',

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),


                const SizedBox(
                  height: 12,
                ),


                if (filtered.isEmpty)

                  Card(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),

                      child:
                          Center(
                        child:
                            Text(
                          deliveries.isEmpty
                              ? 'Nenhuma entrega encontrada.'
                              : 'Nenhuma entrega corresponde ao filtro.',
                        ),
                      ),
                    ),
                  )


                else

                  ...filtered.map(
                    (delivery) {

                      final deliveryId =
                          int.parse(
                        delivery['id']
                            .toString(),
                      );


                      final orderId =
                          delivery['order_id'];


                      final customerName =
                          delivery['customer_name'] ??
                              'Cliente não informado';


                      final churchName =
                          delivery['church_name'] ??
                              'Igreja não informada';


                      final status =
                          delivery['status'];


                      final paymentStatus =
                          delivery['payment_status'];


                      final orderTotal =
                          delivery['order_total'];


                      final deliveryColor =
                          statusColor(
                        status,
                      );


                      final paymentColor =
                          paymentStatusColor(
                        paymentStatus,
                      );


                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),

                        child:
                            InkWell(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),

                          onTap:
                              () async {

                            await Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        AdminDeliveryDetailScreen(
                                  deliveryId:
                                      deliveryId,
                                ),
                              ),
                            );


                            await reloadDeliveries();
                          },

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

                                // ====================================
                                // CABEÇALHO
                                // ====================================

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,

                                  children: [

                                    Text(
                                      'Pedido #$orderId',

                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),


                                    Text(
                                      formatMoney(
                                        orderTotal,
                                      ),

                                      style:
                                          const TextStyle(
                                        fontSize: 17,
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
                                  'Cliente: ${customerName.toString()}',
                                ),


                                const SizedBox(
                                  height: 6,
                                ),


                                Text(
                                  'Igreja: ${churchName.toString()}',
                                ),


                                const SizedBox(
                                  height: 10,
                                ),


                                Row(
                                  children: [

                                    const Icon(
                                      Icons.payment,
                                      size: 19,
                                    ),


                                    const SizedBox(
                                      width: 7,
                                    ),


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
                                            paymentColor,

                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),


                                const SizedBox(
                                  height: 8,
                                ),


                                Row(
                                  children: [

                                    const Icon(
                                      Icons.local_shipping,
                                      size: 19,
                                    ),


                                    const SizedBox(
                                      width: 7,
                                    ),


                                    const Text(
                                      'Entrega: ',
                                    ),


                                    Text(
                                      statusText(
                                        status,
                                      ),

                                      style:
                                          TextStyle(
                                        color:
                                            deliveryColor,

                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),


                                const SizedBox(
                                  height: 12,
                                ),


                                const Align(
                                  alignment:
                                      Alignment.centerRight,

                                  child:
                                      Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
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