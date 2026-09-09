import 'package:flutter/material.dart';

import '../services/admin_user_service.dart';
import 'admin_client_detail_screen.dart';


class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({
    super.key,
  });

  @override
  State<AdminClientsScreen> createState() =>
      _AdminClientsScreenState();
}


class _AdminClientsScreenState
    extends State<AdminClientsScreen> {

  final AdminUserService adminUserService =
      AdminUserService();


  late Future<List<Map<String, dynamic>>>
      clientsFuture;


  String search = '';


  @override
  void initState() {
    super.initState();

    clientsFuture =
        adminUserService.listClients();
  }


  Future<void> reloadClients() async {
    setState(() {
      clientsFuture =
          adminUserService.listClients();
    });

    await clientsFuture;
  }


  String formatMoney(dynamic value) {
    final amount =
        double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;


    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }


  List<Map<String, dynamic>> filterClients(
    List<Map<String, dynamic>> clients,
  ) {

    final query =
        search.trim().toLowerCase();


    if (query.isEmpty) {
      return clients;
    }


    return clients.where(
      (client) {

        final name =
            client['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final email =
            client['email']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final phone =
            client['phone']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      },
    ).toList();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Clientes',
        ),

        actions: [

          IconButton(
            tooltip:
                'Atualizar',

            onPressed:
                reloadClients,

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
            clientsFuture,

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
                          'Erro ao carregar clientes',

                      textAlign:
                          TextAlign.center,
                    ),


                    const SizedBox(
                      height: 16,
                    ),


                    ElevatedButton(
                      onPressed:
                          reloadClients,

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


          final clients =
              snapshot.data ?? [];


          final filteredClients =
              filterClients(
            clients,
          );


          return RefreshIndicator(
            onRefresh:
                reloadClients,

            child:
                ListView(
              padding:
                  const EdgeInsets.all(
                16,
              ),

              children: [

                // ==================================================
                // BUSCA
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
                        'Pesquisar cliente',

                    hintText:
                        'Nome, e-mail ou telefone',

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
                  height: 20,
                ),


                Text(
                  '${filteredClients.length} cliente(s)',

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


                if (filteredClients.isEmpty)

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
                          search.isEmpty
                              ? 'Nenhum cliente cadastrado.'
                              : 'Nenhum cliente encontrado.',
                        ),
                      ),
                    ),
                  )


                else

                  ...filteredClients.map(
                    (client) {

                      final clientId =
                          int.parse(
                        client['id'].toString(),
                      );


                      final name =
                          client['name'] ??
                              'Cliente';


                      final email =
                          client['email'] ??
                              'E-mail não informado';


                      final phone =
                          client['phone'] ??
                              'Telefone não informado';


                      final churchName =
                          client['church_name'] ??
                              'Igreja não informada';


                      final orderCount =
                          client['order_count'] ??
                              0;


                      final approvedTotal =
                          client['approved_total'];


                      final active =
                          client['active'] == true;


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
                                        AdminClientDetailScreen(
                                  clientId:
                                      clientId,
                                ),
                              ),
                            );

                            await reloadClients();
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

                                Row(
                                  children: [

                                    const CircleAvatar(
                                      child:
                                          Icon(
                                        Icons.person,
                                      ),
                                    ),


                                    const SizedBox(
                                      width: 12,
                                    ),


                                    Expanded(
                                      child:
                                          Text(
                                        name.toString(),

                                        style:
                                            const TextStyle(
                                          fontSize: 18,
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
                                  height: 14,
                                ),


                                Text(
                                  email.toString(),
                                ),


                                const SizedBox(
                                  height: 6,
                                ),


                                Text(
                                  phone.toString(),
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

                                    Expanded(
                                      child:
                                          Text(
                                        'Pedidos: $orderCount',
                                      ),
                                    ),


                                    Text(
                                      'Compras aprovadas: ${formatMoney(approvedTotal)}',

                                      style:
                                          const TextStyle(
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
                                    Icons
                                        .arrow_forward_ios,

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