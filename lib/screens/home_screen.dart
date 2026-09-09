import 'package:flutter/material.dart';

import '../services/token_storage.dart';
import '../services/auth_service.dart';

import 'revistas_screen.dart';
import 'biblias_screen.dart';
import 'outros_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TokenStorage tokenStorage = TokenStorage();

  final AuthService authService = AuthService();

  bool loggedIn = false;
  bool checkingLogin = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();

    checkLogin();
  }

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
    } catch (error) {
      await tokenStorage.removeToken();

      if (!mounted) {
        return;
      }

      setState(() {
        loggedIn = false;
        isAdmin = false;
        checkingLogin = false;
      });
    }
  }

  Future<void> openAccount() async {
    if (!loggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      await checkLogin();

      return;
    }

    await showModalBottomSheet(
      context: context,

      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),

                title: const Text('Minhas compras'),

                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    this.context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),

              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),

                  title: const Text('Área ADM'),

                  onTap: () async {
                    Navigator.pop(context);

                    await Navigator.push(
                      this.context,
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
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EBD V2'),

        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),

            tooltip: 'Carrinho',

            onPressed: () async {
              if (!loggedIn) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );

                await checkLogin();

                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12),

            child: checkingLogin
                ? const SizedBox(
                    width: 60,

                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: openAccount,

                    child: Text(loggedIn ? 'Conta' : 'Entrar'),
                  ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text(
              'Categorias',

              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                child: const Text('Revistas EBD'),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RevistasScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                child: const Text('Bíblias'),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BibliasScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                child: const Text('Livros e Outros'),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OutrosScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
