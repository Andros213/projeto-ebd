import 'package:flutter/material.dart';

import '../services/admin_church_service.dart';


class AdminChurchesScreen extends StatefulWidget {
  const AdminChurchesScreen({
    super.key,
  });


  @override
  State<AdminChurchesScreen> createState() =>
      _AdminChurchesScreenState();
}


class _AdminChurchesScreenState
    extends State<AdminChurchesScreen> {

  final AdminChurchService adminChurchService =
      AdminChurchService();


  late Future<List<Map<String, dynamic>>>
      churchesFuture;


  String search = '';


  @override
  void initState() {
    super.initState();

    churchesFuture =
        adminChurchService.listChurches();
  }


  Future<void> reloadChurches() async {

    setState(() {
      churchesFuture =
          adminChurchService.listChurches();
    });


    await churchesFuture;
  }


  List<Map<String, dynamic>> filterChurches(
    List<Map<String, dynamic>> churches,
  ) {

    final query =
        search.trim().toLowerCase();


    if (query.isEmpty) {
      return churches;
    }


    return churches.where(
      (church) {

        final name =
            church['name']
                    ?.toString()
                    .toLowerCase() ??
                '';


        return name.contains(query);
      },
    ).toList();
  }


  Future<void> showChurchForm({
    Map<String, dynamic>? church,
  }) async {

    final controller =
        TextEditingController(
      text:
          church?['name']?.toString() ?? '',
    );


    final isEditing =
        church != null;


    final result =
        await showDialog<bool>(
      context: context,

      builder:
          (dialogContext) {

        return AlertDialog(

          title:
              Text(
            isEditing
                ? 'Editar igreja'
                : 'Nova igreja',
          ),

          content:
              TextField(
            controller:
                controller,

            autofocus:
                true,

            textCapitalization:
                TextCapitalization.words,

            decoration:
                const InputDecoration(
              labelText:
                  'Nome da igreja',

              border:
                  OutlineInputBorder(),
            ),
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
                  () async {

                final name =
                    controller.text.trim();


                if (name.isEmpty) {

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content:
                          Text(
                        'Digite o nome da igreja.',
                      ),
                    ),
                  );


                  return;
                }


                try {

                  if (isEditing) {

                    await adminChurchService
                        .updateChurch(
                      churchId:
                          int.parse(
                        church['id'].toString(),
                      ),

                      name:
                          name,
                    );

                  } else {

                    await adminChurchService
                        .createChurch(
                      name,
                    );
                  }


                  if (!dialogContext.mounted) {
                    return;
                  }


                  Navigator.pop(
                    dialogContext,
                    true,
                  );

                } catch (error) {

                  if (!dialogContext.mounted) {
                    return;
                  }


                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content:
                          Text(
                        error.toString(),
                      ),
                    ),
                  );
                }
              },

              child:
                  Text(
                isEditing
                    ? 'Salvar'
                    : 'Criar',
              ),
            ),
          ],
        );
      },
    );


    controller.dispose();


    if (result == true) {

      await reloadChurches();


      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(
            isEditing
                ? 'Igreja atualizada com sucesso.'
                : 'Igreja criada com sucesso.',
          ),
        ),
      );
    }
  }


  Future<void> toggleChurch(
    Map<String, dynamic> church,
  ) async {

    final churchId =
        int.parse(
      church['id'].toString(),
    );


    final currentActive =
        church['active'] == true;


    final newActive =
        !currentActive;


    final action =
        newActive
            ? 'ativar'
            : 'desativar';


    final confirmed =
        await showDialog<bool>(
      context: context,

      builder:
          (dialogContext) {

        return AlertDialog(

          title:
              Text(
            '${newActive ? 'Ativar' : 'Desativar'} igreja',
          ),

          content:
              Text(
            'Deseja $action a igreja "${church['name']}"?',
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


    if (confirmed != true) {
      return;
    }


    try {

      await adminChurchService.setChurchActive(
        churchId:
            churchId,

        active:
            newActive,
      );


      await reloadChurches();


      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(
            newActive
                ? 'Igreja ativada com sucesso.'
                : 'Igreja desativada com sucesso.',
          ),
        ),
      );

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
          'Igrejas',
        ),

        actions: [

          IconButton(
            tooltip:
                'Atualizar',

            onPressed:
                reloadChurches,

            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),


      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            () {
          showChurchForm();
        },

        icon:
            const Icon(
          Icons.add,
        ),

        label:
            const Text(
          'Nova igreja',
        ),
      ),


      body:
          FutureBuilder<
              List<Map<String, dynamic>>>(
        future:
            churchesFuture,

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
                          'Erro ao carregar igrejas',

                      textAlign:
                          TextAlign.center,
                    ),


                    const SizedBox(
                      height: 16,
                    ),


                    ElevatedButton(
                      onPressed:
                          reloadChurches,

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


          final churches =
              snapshot.data ?? [];


          final filtered =
              filterChurches(
            churches,
          );


          return RefreshIndicator(
            onRefresh:
                reloadChurches,

            child:
                ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
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
                        'Pesquisar igreja',

                    hintText:
                        'Digite o nome da igreja',

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
                  '${filtered.length} igreja(s)',

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
                          churches.isEmpty
                              ? 'Nenhuma igreja cadastrada.'
                              : 'Nenhuma igreja encontrada.',
                        ),
                      ),
                    ),
                  )


                else

                  ...filtered.map(
                    (church) {

                      final churchId =
                          church['id'];


                      final name =
                          church['name']
                                  ?.toString() ??
                              'Igreja';


                      final active =
                          church['active'] == true;


                      final clientCount =
                          church['client_count']
                                  ?.toString() ??
                              '0';


                      final orderCount =
                          church['order_count']
                                  ?.toString() ??
                              '0';


                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
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

                              // ====================================
                              // CABEÇALHO
                              // ====================================

                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Container(
                                    width:
                                        48,

                                    height:
                                        48,

                                    decoration:
                                        BoxDecoration(
                                      color:
                                          active
                                              ? Colors.green.withValues(
                                                  alpha:
                                                      0.12,
                                                )
                                              : Colors.grey.withValues(
                                                  alpha:
                                                      0.12,
                                                ),

                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                    ),

                                    child:
                                        Icon(
                                      Icons.church_outlined,

                                      color:
                                          active
                                              ? Colors.green
                                              : Colors.grey,

                                      size:
                                          26,
                                    ),
                                  ),


                                  const SizedBox(
                                    width:
                                        12,
                                  ),


                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        Text(
                                          name,

                                          style:
                                              const TextStyle(
                                            fontSize:
                                                18,

                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),


                                        const SizedBox(
                                          height:
                                              5,
                                        ),


                                        Row(
                                          children: [

                                            Icon(
                                              Icons.circle,

                                              size:
                                                  10,

                                              color:
                                                  active
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),


                                            const SizedBox(
                                              width:
                                                  6,
                                            ),


                                            Text(
                                              active
                                                  ? 'Ativa'
                                                  : 'Inativa',

                                              style:
                                                  TextStyle(
                                                color:
                                                    active
                                                        ? Colors.green
                                                        : Colors.grey,

                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),


                              const SizedBox(
                                height:
                                    14,
                              ),


                              // ====================================
                              // RESUMO
                              // ====================================

                              Wrap(
                                spacing:
                                    20,

                                runSpacing:
                                    10,

                                children: [

                                  Row(
                                    mainAxisSize:
                                        MainAxisSize.min,

                                    children: [

                                      const Icon(
                                        Icons.people_outline,

                                        size:
                                            20,
                                      ),


                                      const SizedBox(
                                        width:
                                            6,
                                      ),


                                      Text(
                                        'Clientes: $clientCount',
                                      ),
                                    ],
                                  ),


                                  Row(
                                    mainAxisSize:
                                        MainAxisSize.min,

                                    children: [

                                      const Icon(
                                        Icons.shopping_bag_outlined,

                                        size:
                                            20,
                                      ),


                                      const SizedBox(
                                        width:
                                            6,
                                      ),


                                      Text(
                                        'Pedidos: $orderCount',
                                      ),
                                    ],
                                  ),
                                ],
                              ),


                              const SizedBox(
                                height:
                                    14,
                              ),


                              // ====================================
                              // AÇÕES
                              // ====================================

                              Wrap(
                                spacing:
                                    8,

                                runSpacing:
                                    8,

                                children: [

                                  OutlinedButton.icon(
                                    onPressed:
                                        () {
                                      showChurchForm(
                                        church:
                                            church,
                                      );
                                    },

                                    icon:
                                        const Icon(
                                      Icons.edit_outlined,
                                    ),

                                    label:
                                        const Text(
                                      'Editar',
                                    ),
                                  ),


                                  OutlinedButton.icon(
                                    onPressed:
                                        () {
                                      toggleChurch(
                                        church,
                                      );
                                    },

                                    icon:
                                        Icon(
                                      active
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                    ),

                                    label:
                                        Text(
                                      active
                                          ? 'Desativar'
                                          : 'Ativar',
                                    ),
                                  ),


                                  ElevatedButton.icon(
                                    onPressed:
                                        () async {

                                      try {

                                        final detail =
                                            await adminChurchService
                                                .getChurchById(
                                          int.parse(
                                            churchId
                                                .toString(),
                                          ),
                                        );


                                        if (!context.mounted) {
                                          return;
                                        }


                                        showDialog(
                                          context:
                                              context,

                                          builder:
                                              (_) {
                                            final clients =
                                                (detail['clients']
                                                            as List?)
                                                        ?.length ??
                                                    0;

                                            final orders =
                                                (detail['orders']
                                                            as List?)
                                                        ?.length ??
                                                    0;

                                            return AlertDialog(
                                              title:
                                                  Text(
                                                name,
                                              ),

                                              content:
                                                  Text(
                                                'Clientes vinculados: $clients\n\nPedidos vinculados: $orders',
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

                                      } catch (error) {

                                        if (!context.mounted) {
                                          return;
                                        }


                                        ScaffoldMessenger
                                            .of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content:
                                                Text(
                                              error.toString(),
                                            ),
                                          ),
                                        );
                                      }
                                    },

                                    icon:
                                        const Icon(
                                      Icons.open_in_new,
                                    ),

                                    label:
                                        const Text(
                                      'Detalhes',
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