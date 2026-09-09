import 'package:flutter/material.dart';

import '../services/admin_order_service.dart';

import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_clients_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_deliveries_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_churches_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminOrderService adminOrderService = AdminOrderService();

  late Future<List<Map<String, dynamic>>> ordersFuture;

  @override
  void initState() {
    super.initState();

    ordersFuture = adminOrderService.listAllOrders();
  }

  Future<void> reloadDashboard() async {
    setState(() {
      ordersFuture = adminOrderService.listAllOrders();
    });

    await ordersFuture;
  }

  String formatMoney(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;

    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  int countOrders(List<Map<String, dynamic>> orders, String status) {
    return orders
        .where((order) => order['status']?.toString() == status)
        .length;
  }

  double totalApprovedSales(List<Map<String, dynamic>> orders) {
    double total = 0;

    for (final order in orders) {
      final paymentStatus = order['payment_status']?.toString();

      if (paymentStatus == 'approved') {
        total += double.tryParse(order['total']?.toString() ?? '') ?? 0;
      }
    }

    return total;
  }

  int countApprovedPayments(List<Map<String, dynamic>> orders) {
    return orders
        .where((order) => order['payment_status']?.toString() == 'approved')
        .length;
  }

  // ==========================================================
  // CARD DE RESUMO
  // ==========================================================

  Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Container(
              width: 48,

              height: 48,

              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),

                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: color, size: 26),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 20,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CARD DE MENU
  // ==========================================================

  Widget buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Container(
                width: 50,

                height: 50,

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(
                  icon,

                  size: 27,

                  color: enabled ? null : Colors.grey,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 17,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(color: enabled ? null : Colors.grey),
                    ),
                  ],
                ),
              ),

              if (enabled) const SizedBox(width: 8),

              if (enabled) const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NAVEGAÇÃO
  // ==========================================================

  Future<void> openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    if (!mounted) {
      return;
    }

    await reloadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,

          alignment: Alignment.centerLeft,

          child: Text('Administração'),
        ),

        actions: [
          IconButton(
            tooltip: 'Atualizar',

            onPressed: reloadDashboard,

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
            return RefreshIndicator(
              onRefresh: reloadDashboard,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                children: [
                  const SizedBox(height: 180),

                  const Icon(Icons.error_outline, size: 50),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),

                    child: Text(
                      snapshot.error?.toString() ??
                          'Erro ao carregar dashboard',

                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: ElevatedButton(
                      onPressed: reloadDashboard,

                      child: const Text('Tentar novamente'),
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          final totalSales = totalApprovedSales(orders);

          final approved = countApprovedPayments(orders);

          final pending = countOrders(orders, 'pending');

          final preparing = countOrders(orders, 'preparing');

          final shipped = countOrders(orders, 'shipped');

          final delivered = countOrders(orders, 'delivered');

          return RefreshIndicator(
            onRefresh: reloadDashboard,

            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                // ========================================================
                // BREAKPOINTS
                // ========================================================

                final isPhone = width < 600;

                final isSmallPhone = width < 400;

                final isTablet = width >= 600 && width < 1000;

                // ========================================================
                // COLUNAS DO RESUMO
                // ========================================================

                final summaryColumns = isSmallPhone
                    ? 1
                    : isPhone
                    ? 1
                    : isTablet
                    ? 2
                    : 4;

                // ========================================================
                // ALTURA DOS CARDS DE RESUMO
                // ========================================================

                final summaryHeight = isSmallPhone
                    ? 96.0
                    : isPhone
                    ? 96.0
                    : isTablet
                    ? 96.0
                    : 100.0;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: EdgeInsets.all(isSmallPhone ? 12 : 16),

                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ==================================================
                          // TÍTULO
                          // ==================================================
                          Text(
                            'Visão geral',

                            style: TextStyle(
                              fontSize: isSmallPhone ? 24 : 26,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Acompanhe os pedidos, pagamentos e operações da loja.',

                            style: TextStyle(
                              color: Colors.grey.shade700,

                              fontSize: isSmallPhone ? 14 : 15,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ==================================================
                          // RESUMO
                          // ==================================================
                          GridView.builder(
                            itemCount: 4,

                            shrinkWrap: true,

                            physics: const NeverScrollableScrollPhysics(),

                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: summaryColumns,

                                  crossAxisSpacing: 12,

                                  mainAxisSpacing: 12,

                                  mainAxisExtent: summaryHeight,
                                ),

                            itemBuilder: (context, index) {
                              switch (index) {
                                case 0:
                                  return buildSummaryCard(
                                    title: 'Vendas aprovadas',

                                    value: formatMoney(totalSales),

                                    icon: Icons.payments_outlined,

                                    color: Colors.green,
                                  );

                                case 1:
                                  return buildSummaryCard(
                                    title: 'Pagamentos aprovados',

                                    value: approved.toString(),

                                    icon: Icons.check_circle_outline,

                                    color: Colors.blue,
                                  );

                                case 2:
                                  return buildSummaryCard(
                                    title: 'Aguardando',

                                    value: pending.toString(),

                                    icon: Icons.pending_actions,

                                    color: Colors.orange,
                                  );

                                default:
                                  return buildSummaryCard(
                                    title: 'Entregues',

                                    value: delivered.toString(),

                                    icon: Icons.local_shipping_outlined,

                                    color: Colors.green,
                                  );
                              }
                            },
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // PEDIDOS POR ETAPA
                          // ==================================================
                          const Text(
                            'Pedidos por etapa',

                            style: TextStyle(
                              fontSize: 20,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),

                              child: Wrap(
                                spacing: isSmallPhone ? 16 : 24,

                                runSpacing: 14,

                                children: [
                                  Text('Aguardando: $pending'),

                                  Text('Preparando: $preparing'),

                                  Text('Enviados: $shipped'),

                                  Text('Entregues: $delivered'),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // ACESSO RÁPIDO
                          // ==================================================
                          const Text(
                            'Acesso rápido',

                            style: TextStyle(
                              fontSize: 20,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ==================================================
                          // DESKTOP / TABLET
                          // ==================================================
                          if (!isPhone)
                            GridView.count(
                              crossAxisCount: 2,

                              crossAxisSpacing: 12,

                              mainAxisSpacing: 12,

                              childAspectRatio: isTablet ? 3.0 : 3.6,

                              shrinkWrap: true,

                              physics: const NeverScrollableScrollPhysics(),

                              children: [
                                // ==========================================
                                // PEDIDOS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Pedidos',

                                  subtitle:
                                      'Consultar pedidos e alterar status',

                                  icon: Icons.shopping_bag_outlined,

                                  onTap: () =>
                                      openPage(const AdminOrdersScreen()),
                                ),

                                // ==========================================
                                // PRODUTOS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Produtos',

                                  subtitle:
                                      'Cadastrar, editar e controlar estoque',

                                  icon: Icons.inventory_2_outlined,

                                  onTap: () =>
                                      openPage(const AdminProductsScreen()),
                                ),

                                // ==========================================
                                // CLIENTES
                                // ==========================================
                                buildMenuCard(
                                  title: 'Clientes',

                                  subtitle: 'Consultar clientes e histórico',

                                  icon: Icons.people_outline,

                                  onTap: () =>
                                      openPage(const AdminClientsScreen()),
                                ),

                                // ==========================================
                                // IGREJAS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Igrejas',

                                  subtitle:
                                      'Gerenciar igrejas, clientes e pedidos',

                                  icon: Icons.church_outlined,

                                  onTap: () =>
                                      openPage(const AdminChurchesScreen()),
                                ),

                                // ==========================================
                                // PAGAMENTOS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Pagamentos',

                                  subtitle:
                                      'Visualizar pagamentos Mercado Pago',

                                  icon: Icons.payments_outlined,

                                  onTap: () =>
                                      openPage(const AdminPaymentsScreen()),
                                ),

                                // ==========================================
                                // ENTREGAS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Entregas',

                                  subtitle:
                                      'Controlar pedidos pagos e entregues',

                                  icon: Icons.local_shipping_outlined,

                                  onTap: () =>
                                      openPage(const AdminDeliveriesScreen()),
                                ),

                                // ==========================================
                                // CONFIGURAÇÕES
                                // ==========================================
                                buildMenuCard(
                                  title: 'Configurações',

                                  subtitle: 'Configurações gerais da loja',

                                  icon: Icons.settings_outlined,

                                  onTap: () =>
                                      openPage(const AdminSettingsScreen()),
                                ),
                              ],
                            )
                          // ==================================================
                          // CELULAR
                          // ==================================================
                          else
                            Column(
                              children: [
                                // ==========================================
                                // PEDIDOS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Pedidos',

                                  subtitle:
                                      'Consultar pedidos e alterar status',

                                  icon: Icons.shopping_bag_outlined,

                                  onTap: () =>
                                      openPage(const AdminOrdersScreen()),
                                ),

                                const SizedBox(height: 12),

                                // ==========================================
                                // PRODUTOS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Produtos',

                                  subtitle:
                                      'Cadastrar, editar e controlar estoque',

                                  icon: Icons.inventory_2_outlined,

                                  onTap: () =>
                                      openPage(const AdminProductsScreen()),
                                ),

                                const SizedBox(height: 12),

                                // ==========================================
                                // CLIENTES
                                // ==========================================
                                buildMenuCard(
                                  title: 'Clientes',

                                  subtitle: 'Consultar clientes e histórico',

                                  icon: Icons.people_outline,

                                  onTap: () =>
                                      openPage(const AdminClientsScreen()),
                                ),

                                const SizedBox(height: 12),

                                // ==========================================
                                // IGREJAS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Igrejas',

                                  subtitle:
                                      'Gerenciar igrejas, clientes e pedidos',

                                  icon: Icons.church_outlined,

                                  onTap: () =>
                                      openPage(const AdminChurchesScreen()),
                                ),

                                const SizedBox(height: 12),

                                // ==========================================
                                // PAGAMENTOS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Pagamentos',

                                  subtitle:
                                      'Visualizar pagamentos Mercado Pago',

                                  icon: Icons.payments_outlined,

                                  onTap: () =>
                                      openPage(const AdminPaymentsScreen()),
                                ),

                                const SizedBox(height: 12),

                                // ==========================================
                                // ENTREGAS
                                // ==========================================
                                buildMenuCard(
                                  title: 'Entregas',

                                  subtitle:
                                      'Controlar pedidos pagos e entregues',

                                  icon: Icons.local_shipping_outlined,

                                  onTap: () =>
                                      openPage(const AdminDeliveriesScreen()),
                                ),

                                const SizedBox(height: 12),

                                // ==========================================
                                // CONFIGURAÇÕES
                                // ==========================================
                                buildMenuCard(
                                  title: 'Configurações',

                                  subtitle: 'Configurações gerais da loja',

                                  icon: Icons.settings_outlined,

                                  onTap: () =>
                                      openPage(const AdminSettingsScreen()),
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // INFORMAÇÃO
                          // ==================================================
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  const Icon(Icons.info_outline),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      'Dashboard, Pedidos, Produtos, Clientes, Pagamentos, Entregas e Igrejas estão disponíveis na área administrativa. Configurações também está disponível como estrutura administrativa.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
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
