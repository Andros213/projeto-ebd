import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/church_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService authService = AuthService();

  final ChurchService churchService = ChurchService();

  late Future<Map<String, dynamic>> user;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    user = authService.getMe();
  }

  String valueOrDefault(dynamic value) {
    if (value == null) {
      return 'Não informado';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return 'Não informado';
    }

    return text;
  }

  String formatPhone(dynamic value) {
    final phone = valueOrDefault(value);

    if (phone == 'Não informado') {
      return phone;
    }

    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) '
          '${digits.substring(2, 7)}-'
          '${digits.substring(7)}';
    }

    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) '
          '${digits.substring(2, 6)}-'
          '${digits.substring(6)}';
    }

    return phone;
  }

  Future<void> saveProfile({
    required int churchId,
    required String? phone,
  }) async {
    if (saving) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final updatedUser = await authService.updateProfile(
        churchId: churchId,
        phone: phone,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        user = Future.value(updatedUser);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso')),
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
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> editPhone(Map<String, dynamic> data) async {
    final controller = TextEditingController(
      text: data['phone']?.toString() ?? '',
    );

    final newPhone = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alterar telefone'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              hintText: '(71) 99999-9999',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newPhone == null) {
      return;
    }

    final churchId = int.tryParse(data['churchId']?.toString() ?? '');

    if (churchId == null) {
      return;
    }

    await saveProfile(
      churchId: churchId,
      phone: newPhone.isEmpty ? null : newPhone,
    );
  }

  Future<void> editChurch(Map<String, dynamic> data) async {
    try {
      final churches = await churchService.getChurches();

      if (!mounted) {
        return;
      }

      final currentChurchId = int.tryParse(data['churchId']?.toString() ?? '');

      final selectedChurchId = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          int? selected = currentChurchId;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Alterar igreja'),
                content: SizedBox(
                  width: 420,
                  child: DropdownButtonFormField<int>(
                    initialValue:
                        churches.any(
                          (church) =>
                              int.tryParse(church['id']?.toString() ?? '') ==
                              currentChurchId,
                        )
                        ? currentChurchId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Igreja',
                      border: OutlineInputBorder(),
                    ),
                    items: churches.map((church) {
                      final id = int.tryParse(church['id']?.toString() ?? '');

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(church['name']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selected = value;
                      });
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () {
                            Navigator.pop(dialogContext, selected);
                          },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selectedChurchId == null) {
        return;
      }

      final phone = data['phone']?.toString();

      await saveProfile(churchId: selectedChurchId, phone: phone);
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

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0AD88)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEED7BA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6A442F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F3021),
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Editar',
              onPressed: saving ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF6A442F)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8ECDD),
      appBar: AppBar(
        title: const Text('Minha Conta'),
        backgroundColor: const Color(0xFFF6EBDD),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar os dados da conta:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};

          final name = valueOrDefault(data['name']);

          final email = valueOrDefault(data['email']);

          final phone = formatPhone(data['phone']);

          final churchName = valueOrDefault(data['churchName']);

          final role = data['role']?.toString() ?? 'customer';

          final isAdmin = role == 'admin';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC39569),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withValues(alpha: 0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F3021),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 26),

                    buildInfoCard(
                      icon: Icons.person_outline,
                      title: 'Nome',
                      value: name,
                    ),

                    buildInfoCard(
                      icon: Icons.email_outlined,
                      title: 'E-mail',
                      value: email,
                    ),

                    buildInfoCard(
                      icon: Icons.phone_outlined,
                      title: 'Telefone',
                      value: phone,
                      onEdit: () => editPhone(data),
                    ),

                    buildInfoCard(
                      icon: Icons.church_outlined,
                      title: 'Igreja',
                      value: churchName,
                      onEdit: () => editChurch(data),
                    ),

                    if (isAdmin)
                      buildInfoCard(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Perfil',
                        value: 'Administrador',
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
