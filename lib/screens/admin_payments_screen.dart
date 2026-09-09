import 'package:flutter/material.dart';

import '../services/admin_payment_service.dart';


class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({
    super.key,
  });

  @override
  State<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}


class _AdminPaymentsScreenState
    extends State<AdminPaymentsScreen> {

  final AdminPaymentService adminPaymentService =
      AdminPaymentService();


  late Future<List<Map<String, dynamic>>>
      paymentsFuture;


  String search = '';
  String selectedStatus = 'all';


  @override
  void initState() {
    super.initState();

    paymentsFuture =
        adminPaymentService.listPayments();
  }


  Future<void> reloadPayments() async {
    setState(() {
      paymentsFuture =
          adminPaymentService.listPayments();
    });

    await paymentsFuture;
  }


  String formatMoney(dynamic value) {
    final amount =
        double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
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

      case 'in_process':
        return 'Em processamento';

      default:
        return 'Não informado';
    }
  }


  Color paymentStatusColor(dynamic status) {
    switch (status?.toString()) {
      case 'approved':
        return Colors.green;

      case 'pending':
      case 'in_process':
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


  List<Map<String, dynamic>> filterPayments(
    List<Map<String, dynamic>> payments,
  ) {

    final query =
        search.trim().toLowerCase();


    return payments.where(
      (payment) {

        final status =
            payment['status']
                    ?.toString() ??
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
            payment['order_id']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final customerName =
            payment['customer_name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final email =
            payment['customer_email']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final providerPaymentId =
            payment['provider_payment_id']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return orderId.contains(query) ||
            customerName.contains(query) ||
            email.contains(query) ||
            providerPaymentId.contains(query);
      },
    ).toList();
  }


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Pagamentos',
        ),

        actions: [
          IconButton(
            tooltip:
                'Atualizar',

            onPressed:
                reloadPayments,

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
            paymentsFuture,

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
                          'Erro ao carregar pagamentos',

                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    ElevatedButton(
                      onPressed:
                          reloadPayments,

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


          final payments =
              snapshot.data ?? [];


          final filteredPayments =
              filterPayments(
            payments,
          );


          return RefreshIndicator(
            onRefresh:
                reloadPayments,

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
                        'Pesquisar pagamento',

                    hintText:
                        'Pedido, cliente ou ID Mercado Pago',

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
                        'Status',

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
                          'approved',

                      child:
                          Text(
                        'Aprovados',
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
                          'rejected',

                      child:
                          Text(
                        'Recusados',
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

                    DropdownMenuItem(
                      value:
                          'refunded',

                      child:
                          Text(
                        'Estornados',
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
                  '${filteredPayments.length} pagamento(s)',

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


                if (filteredPayments.isEmpty)

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
                          payments.isEmpty
                              ? 'Nenhum pagamento encontrado.'
                              : 'Nenhum pagamento corresponde ao filtro.',
                        ),
                      ),
                    ),
                  )


                else

                  ...filteredPayments.map(
                    (payment) {

                      final paymentId =
                          int.parse(
                        payment['id']
                            .toString(),
                      );


                      final orderId =
                          payment['order_id'];


                      final customerName =
                          payment['customer_name'] ??
                              'Cliente não informado';


                      final amount =
                          payment['amount'];


                      final status =
                          payment['status'];


                      final paymentMethod =
                          payment['payment_method'] ??
                              'Não informado';


                      final providerPaymentId =
                          payment['provider_payment_id'] ??
                              'Não informado';


                      final color =
                          paymentStatusColor(
                        status,
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
                              () {
                            showDialog(
                              context:
                                  context,

                              builder:
                                  (_) {
                                return AlertDialog(
                                  title:
                                      Text(
                                    'Pagamento #$paymentId',
                                  ),

                                  content:
                                      SingleChildScrollView(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      mainAxisSize:
                                          MainAxisSize.min,

                                      children: [

                                        Text(
                                          'Pedido: #$orderId',
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        Text(
                                          'Cliente: ${customerName.toString()}',
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        Text(
                                          'Valor: ${formatMoney(amount)}',
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        Text(
                                          'Método: ${paymentMethod.toString()}',
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        Text(
                                          'Mercado Pago: ${providerPaymentId.toString()}',
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        Row(
                                          children: [

                                            const Text(
                                              'Status: ',
                                            ),

                                            Text(
                                              paymentStatusText(
                                                status,
                                              ),

                                              style:
                                                  TextStyle(
                                                color:
                                                    color,

                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () {
                                        Navigator.pop(
                                          context,
                                        );
                                      },

                                      child:
                                          const Text(
                                        'Fechar',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
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
                                  CrossAxisAlignment.start,

                              children: [

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,

                                  children: [

                                    Text(
                                      'Pagamento #$paymentId',

                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),


                                    Text(
                                      formatMoney(
                                        amount,
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
                                  'Pedido: #$orderId',
                                ),


                                const SizedBox(
                                  height: 6,
                                ),


                                Text(
                                  'Cliente: ${customerName.toString()}',
                                ),


                                const SizedBox(
                                  height: 6,
                                ),


                                Text(
                                  'Método: ${paymentMethod.toString()}',
                                ),


                                const SizedBox(
                                  height: 10,
                                ),


                                Row(
                                  children: [

                                    Icon(
                                      Icons.circle,

                                      size: 12,

                                      color:
                                          color,
                                    ),


                                    const SizedBox(
                                      width: 8,
                                    ),


                                    Text(
                                      paymentStatusText(
                                        status,
                                      ),

                                      style:
                                          TextStyle(
                                        color:
                                            color,

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
                                  'ID Mercado Pago: ${providerPaymentId.toString()}',

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey.shade700,

                                    fontSize: 13,
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