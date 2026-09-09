import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/token_storage.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();
  final TokenStorage tokenStorage = TokenStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final token = await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await tokenStorage.saveToken(token);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);

      debugPrint('JWT recebido e salvo com sucesso');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const Text(
                  'Entrar na conta',

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: emailController,

                  keyboardType: TextInputType.emailAddress,

                  decoration: const InputDecoration(
                    labelText: 'E-mail',

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,

                  obscureText: true,

                  decoration: const InputDecoration(
                    labelText: 'Senha',

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                if (errorMessage != null)
                  Text(
                    errorMessage!,

                    textAlign: TextAlign.center,

                    style: const TextStyle(color: Colors.red),
                  ),

                if (errorMessage != null) const SizedBox(height: 15),

                SizedBox(
                  height: 50,

                  child: ElevatedButton(
                    onPressed: loading ? null : login,

                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,

                            child: CircularProgressIndicator(),
                          )
                        : const Text('Entrar'),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },

                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
