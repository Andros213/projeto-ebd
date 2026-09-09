import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/church_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService authService = AuthService();
  final ChurchService churchService = ChurchService();

  final TextEditingController firstNameController = TextEditingController();

  final TextEditingController lastNameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  late Future<List<Map<String, dynamic>>> churches;

  int? selectedChurchId;

  bool loading = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    churches = churchService.getChurches();
  }

  Future<void> register() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final firstName = firstNameController.text.trim();

      final lastName = lastNameController.text.trim();

      final email = emailController.text.trim();

      final phone = phoneController.text.trim();

      final password = passwordController.text;

      final confirmPassword = confirmPasswordController.text;

      if (firstName.isEmpty) {
        throw Exception('Informe seu nome');
      }

      if (lastName.isEmpty) {
        throw Exception('Informe seu sobrenome');
      }

      if (email.isEmpty) {
        throw Exception('Informe seu e-mail');
      }

      if (selectedChurchId == null) {
        throw Exception('Selecione uma igreja');
      }

      if (password.length < 6) {
        throw Exception('A senha deve ter pelo menos 6 caracteres');
      }

      if (password != confirmPassword) {
        throw Exception('As senhas não coincidem');
      }

      final fullName = '$firstName $lastName';

      await authService.register(
        churchId: selectedChurchId!,
        name: fullName,
        email: email,
        phone: phone.isEmpty ? null : phone,
        password: password,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso')),
      );

      Navigator.pop(context);
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
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const Text(
                  'Criar conta',

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: firstNameController,

                  decoration: const InputDecoration(
                    labelText: 'Nome',

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: lastNameController,

                  decoration: const InputDecoration(
                    labelText: 'Sobrenome',

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

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
                  controller: phoneController,

                  keyboardType: TextInputType.phone,

                  decoration: const InputDecoration(
                    labelText: 'Telefone',

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: churches,

                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text(
                        'Erro ao carregar igrejas: '
                        '${snapshot.error}',
                      );
                    }

                    final churchList = snapshot.data ?? [];

                    if (churchList.isEmpty) {
                      return const Text('Nenhuma igreja disponível');
                    }

                    return DropdownButtonFormField<int>(
                      initialValue: selectedChurchId,

                      decoration: const InputDecoration(
                        labelText: 'Igreja',

                        border: OutlineInputBorder(),
                      ),

                      items: churchList
                          .map((church) {
                            final id = int.tryParse(church['id'].toString());

                            final churchName =
                                church['name']?.toString() ??
                                church['nome']?.toString() ??
                                'Igreja';

                            return DropdownMenuItem<int>(
                              value: id,

                              child: Text(churchName),
                            );
                          })
                          .where((item) => item.value != null)
                          .toList(),

                      onChanged: (value) {
                        setState(() {
                          selectedChurchId = value;
                        });
                      },
                    );
                  },
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

                TextField(
                  controller: confirmPasswordController,

                  obscureText: true,

                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',

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
                    onPressed: loading ? null : register,

                    child: loading
                        ? const SizedBox(
                            width: 24,

                            height: 24,

                            child: CircularProgressIndicator(),
                          )
                        : const Text('Cadastrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
