import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/token_storage.dart';

import 'admin_dashboard_screen.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final ProductService productService = ProductService();
  final TokenStorage tokenStorage = TokenStorage();
  final AuthService authService = AuthService();
  final CartService cartService = CartService();

  final TextEditingController searchController = TextEditingController();

  int selectedIndex = 0;

  bool loadingProducts = true;
  bool checkingLogin = true;
  bool loggedIn = false;
  bool isAdmin = false;

  int cartItemCount = 0;

  String searchText = '';

  List<ProductModel> allProducts = [];

  @override
  void initState() {
    super.initState();

    loadProducts();
    checkLogin();

    searchController.addListener(() {
      if (!mounted) {
        return;
      }

      setState(() {
        searchText = searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PRODUTOS
  // ==========================================================

  Future<void> loadProducts() async {
    try {
      final products = await productService.getProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        allProducts = products.where((product) => product.active).toList();
        loadingProducts = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ERRO AO CARREGAR PRODUTOS: $error');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        loadingProducts = false;
      });
    }
  }

  // ==========================================================
  // CONTADOR DO CARRINHO
  // ==========================================================

  Future<void> loadCartCount() async {
    if (!loggedIn) {
      if (!mounted) {
        return;
      }

      setState(() {
        cartItemCount = 0;
      });

      return;
    }

    try {
      final data = await cartService.getCart();

      final items = data['items'] as List? ?? [];

      int totalQuantity = 0;

      for (final item in items) {
        totalQuantity += int.tryParse(item['quantity']?.toString() ?? '') ?? 0;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        cartItemCount = totalQuantity;
      });
    } catch (error) {
      debugPrint('ERRO AO CARREGAR CONTADOR DO CARRINHO: $error');
    }
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> checkLogin() async {
    final hasToken = await tokenStorage.hasToken();

    if (!hasToken) {
      if (!mounted) {
        return;
      }

      setState(() {
        loggedIn = false;
        isAdmin = false;
        checkingLogin = false;
        cartItemCount = 0;
      });

      return;
    }

    try {
      final user = await authService.getMe();
      final role = user['role']?.toString();

      if (!mounted) {
        return;
      }

      setState(() {
        loggedIn = true;
        isAdmin = role == 'admin';
        checkingLogin = false;
      });

      await loadCartCount();
    } catch (_) {
      await tokenStorage.removeToken();

      if (!mounted) {
        return;
      }

      setState(() {
        loggedIn = false;
        isAdmin = false;
        checkingLogin = false;
        cartItemCount = 0;
      });
    }
  }

  // ==========================================================
  // FILTROS
  // ==========================================================

  List<ProductModel> get revistas {
    return allProducts
        .where((product) => product.type == 'revista')
        .where(matchesSearch)
        .toList();
  }

  List<ProductModel> get biblias {
    return allProducts
        .where((product) => product.type == 'biblia')
        .where(matchesSearch)
        .toList();
  }

  List<ProductModel> get outros {
    return allProducts
        .where(
          (product) => product.type != 'revista' && product.type != 'biblia',
        )
        .where(matchesSearch)
        .toList();
  }

  bool matchesSearch(ProductModel product) {
    if (searchText.isEmpty) {
      return true;
    }

    final name = product.name.toLowerCase();
    final type = product.type.toLowerCase();
    final description = product.description?.toLowerCase() ?? '';

    return name.contains(searchText) ||
        type.contains(searchText) ||
        description.contains(searchText);
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    await checkLogin();
  }

  // ==========================================================
  // CARRINHO
  // ==========================================================

  Future<void> openCart() async {
    if (!loggedIn) {
      await openLogin();
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );

    await loadCartCount();
  }

  // ==========================================================
  // CONTA
  // ==========================================================

  Future<void> openAccount() async {
    if (!loggedIn) {
      await openLogin();
      return;
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Minha Conta'),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('Minhas compras'),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),

              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Área ADM'),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),

              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Fechar'),
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // ADICIONAR AO CARRINHO
  // ==========================================================

  Future<void> addToCart(ProductModel product) async {
    if (product.stock <= 0) {
      return;
    }

    if (!loggedIn) {
      await openLogin();
      return;
    }

    try {
      await cartService.addToCart(productId: product.id, quantity: 1);

      await loadCartCount();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} foi adicionado ao carrinho')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ==========================================================
  // DETALHES
  // ==========================================================

  void openProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  // ==========================================================
  // PESQUISA
  // ==========================================================

  Widget buildSearchField() {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Pesquisar...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchText.isNotEmpty
            ? IconButton(
                tooltip: 'Limpar',
                onPressed: () {
                  searchController.clear();
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ==========================================================
  // TOPO
  // ==========================================================

  Widget buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EBDD),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;

            // ==================================================
            // MOBILE
            // ==================================================

            if (compact) {
              return Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 29,
                    color: Color(0xFF65412D),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'EBD',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4F3021),
                    ),
                  ),
                  const SizedBox(width: 7),

                  // PESQUISA
                  Expanded(
                    child: SizedBox(height: 44, child: buildSearchField()),
                  ),

                  const SizedBox(width: 2),

                  // CONTA
                  SizedBox(
                    width: 40,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: loggedIn ? 'Conta' : 'Entrar',
                      onPressed: openAccount,
                      icon: Icon(
                        loggedIn
                            ? Icons.account_circle_outlined
                            : Icons.person_outline,
                        color: const Color(0xFF6A442F),
                        size: 25,
                      ),
                    ),
                  ),

                  // CARRINHO
                  SizedBox(
                    width: 40,
                    height: 44,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: openCart,
                          tooltip: 'Carrinho',
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Color(0xFF6A442F),
                            size: 25,
                          ),
                        ),
                        Positioned(
                          right: -1,
                          top: -2,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 19,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC39569),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              cartItemCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ==================================================
            // DESKTOP / TABLET
            // ==================================================

            return Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 36,
                  color: Color(0xFF65412D),
                ),
                const SizedBox(width: 10),
                const Text(
                  'EBD',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F3021),
                  ),
                ),
                const SizedBox(width: 28),

                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SizedBox(height: 48, child: buildSearchField()),
                  ),
                ),

                const Spacer(),

                // CARRINHO
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Carrinho',
                      onPressed: openCart,
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFF6A442F),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC39569),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cartItemCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                // CONTA
                TextButton(
                  onPressed: openAccount,
                  child: Text(
                    checkingLogin
                        ? '...'
                        : loggedIn
                        ? 'Conta'
                        : 'Entrar',
                    style: const TextStyle(
                      color: Color(0xFF5B3927),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // BANNER
  // ==========================================================

  Widget buildBanner() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 175, maxHeight: 235),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFB98C62), Color(0xFFE1BE95)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -25,
            child: Icon(
              Icons.menu_book_rounded,
              size: 190,
              color: Colors.white.withValues(alpha: 0.11),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Materiais de',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'Escola Dominical',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aprenda, ensine e cresça na Palavra.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.auto_stories_rounded,
                  size: 96,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TÍTULO DA SEÇÃO
  // ==========================================================

  Widget buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4F3021),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  // ==========================================================
  // CARD DO PRODUTO
  // ==========================================================

  Widget buildProductCard(ProductModel product) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD0AD88), width: 1.2),
      ),
      color: const Color(0xFFFFF7ED),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openProduct(product),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // IMAGEM
              // ==================================================
              SizedBox(
                height: 110,
                width: double.infinity,
                child: Center(
                  child: Container(
                    width: 88,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEED7BA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 38,
                                  color: Color(0xFF8C674C),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 44,
                              color: Color(0xFF8C674C),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // NOME
              // ==================================================
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Color(0xFF4F3021),
                ),
              ),

              const SizedBox(height: 4),

              // ==================================================
              // DESCRIÇÃO / CLASSE
              // ==================================================
              Text(
                product.description?.isNotEmpty == true
                    ? product.description!
                    : product.className?.isNotEmpty == true
                    ? product.className!
                    : 'Material para estudo bíblico',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.15,
                  color: Colors.black87,
                ),
              ),

              const Spacer(),

              // ==================================================
              // PREÇO
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: Text(
                  'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F3021),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ==================================================
              // BOTÃO
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: product.stock > 0
                      ? () => addToCart(product)
                      : null,
                  icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                  label: Text(
                    product.stock > 0 ? 'Adicionar ao carrinho' : 'Sem estoque',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC39569),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // GRADE
  // ==========================================================

  Widget buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD0AD88)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 52,
              color: Color(0xFF9A7556),
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum produto encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1050
            ? 4
            : width >= 760
            ? 3
            : 2;

        final aspectRatio = width < 600 ? 0.62 : 0.90;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return buildProductCard(products[index]);
          },
        );
      },
    );
  }

  // ==========================================================
  // HOME
  // ==========================================================

  Widget buildHomeTab() {
    final highlighted = revistas.take(8).toList();

    return RefreshIndicator(
      onRefresh: loadProducts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          buildBanner(),
          const SizedBox(height: 28),
          buildSectionTitle(
            title: 'Revistas EBD em Destaque',
            subtitle: 'Novidades e destaques do mês',
          ),
          const SizedBox(height: 16),
          buildProductGrid(highlighted),
        ],
      ),
    );
  }

  // ==========================================================
  // CATEGORIAS
  // ==========================================================

  Widget buildCategoryTab({
    required String title,
    required String subtitle,
    required List<ProductModel> products,
  }) {
    return RefreshIndicator(
      onRefresh: loadProducts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          buildSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          buildProductGrid(products),
        ],
      ),
    );
  }

  // ==========================================================
  // PÁGINA ATUAL
  // ==========================================================

  Widget buildCurrentPage() {
    if (loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    return IndexedStack(
      index: selectedIndex,
      children: [
        buildHomeTab(),
        buildCategoryTab(
          title: 'Bíblias',
          subtitle: 'Encontre a Bíblia ideal para você',
          products: biblias,
        ),
        buildCategoryTab(
          title: 'Outros',
          subtitle: 'Livros e materiais para seu crescimento',
          products: outros,
        ),
      ],
    );
  }

  // ==========================================================
  // NAVEGAÇÃO INFERIOR
  // ==========================================================

  Widget buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      backgroundColor: const Color(0xFFFFF4E7),
      indicatorColor: const Color(0xFFC79D72),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: 'Bíblias',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz),
          label: 'Outros',
        ),
      ],
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8ECDD),
      body: Column(
        children: [
          buildTopBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: buildCurrentPage(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }
}
