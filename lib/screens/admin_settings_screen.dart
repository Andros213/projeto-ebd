import 'package:flutter/material.dart';

import '../services/admin_settings_service.dart';
import '../services/auth_service.dart';

import 'admin_cloudinary_screen.dart';
import 'login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AdminSettingsService adminSettingsService = AdminSettingsService();

  final AuthService authService = AuthService();

  final TextEditingController storeNameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  bool loadingSettings = true;

  bool savingSettings = false;

  // ==========================================================
  // CONTA ADMINISTRATIVA
  // ==========================================================

  String adminName = '';

  String adminEmail = '';

  bool loadingAdminAccount = false;

  // ==========================================================
  // NOTIFICAÇÕES
  // ==========================================================

  bool notifyNewOrder = true;

  bool notifyPaymentApproved = true;

  bool notifyOrderConfirmed = true;

  bool notifyOrderPreparing = true;

  bool notifyOrderShipped = true;

  bool notifyOrderDelivered = true;

  @override
  void initState() {
    super.initState();

    loadSettings();

    loadAdminAccount();
  }

  @override
  void dispose() {
    storeNameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    super.dispose();
  }

  // ==========================================================
  // CARREGAR CONFIGURAÇÕES
  // ==========================================================

  Future<void> loadSettings() async {
    if (!mounted) {
      return;
    }

    setState(() {
      loadingSettings = true;
    });

    try {
      final settings = await adminSettingsService.getSettings();

      if (!mounted) {
        return;
      }

      storeNameController.text = settings['store_name']?.toString() ?? '';

      phoneController.text = settings['phone']?.toString() ?? '';

      emailController.text = settings['email']?.toString() ?? '';

      notifyNewOrder = settings['notify_new_order'] == true;

      notifyPaymentApproved = settings['notify_payment_approved'] == true;

      notifyOrderConfirmed = settings['notify_order_confirmed'] == true;

      notifyOrderPreparing = settings['notify_order_preparing'] == true;

      notifyOrderShipped = settings['notify_order_shipped'] == true;

      notifyOrderDelivered = settings['notify_order_delivered'] == true;
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
      if (!mounted) {
        return;
      }

      setState(() {
        loadingSettings = false;
      });
    }
  }

  // ==========================================================
  // CARREGAR CONTA ADMINISTRATIVA
  // ==========================================================

  Future<void> loadAdminAccount() async {
    if (!mounted) {
      return;
    }

    setState(() {
      loadingAdminAccount = true;
    });

    try {
      final user = await authService.getMe();

      if (!mounted) {
        return;
      }

      adminName = user['name']?.toString() ?? '';

      adminEmail = user['email']?.toString() ?? '';
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível carregar os dados da conta: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        loadingAdminAccount = false;
      });
    }
  }

  // ==========================================================
  // SALVAR CONFIGURAÇÕES
  // ==========================================================

  Future<void> saveSettings() async {
    if (savingSettings) {
      return;
    }

    final storeName = storeNameController.text.trim();

    final phone = phoneController.text.trim();

    final email = emailController.text.trim();

    if (storeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da loja é obrigatório.')),
      );

      return;
    }

    setState(() {
      savingSettings = true;
    });

    try {
      final settings = await adminSettingsService.updateSettings(
        storeName: storeName,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        notifyNewOrder: notifyNewOrder,
        notifyPaymentApproved: notifyPaymentApproved,
        notifyOrderConfirmed: notifyOrderConfirmed,
        notifyOrderPreparing: notifyOrderPreparing,
        notifyOrderShipped: notifyOrderShipped,
        notifyOrderDelivered: notifyOrderDelivered,
      );

      if (!mounted) {
        return;
      }

      storeNameController.text =
          settings['store_name']?.toString() ?? storeName;

      phoneController.text = settings['phone']?.toString() ?? '';

      emailController.text = settings['email']?.toString() ?? '';

      notifyNewOrder = settings['notify_new_order'] == true;

      notifyPaymentApproved = settings['notify_payment_approved'] == true;

      notifyOrderConfirmed = settings['notify_order_confirmed'] == true;

      notifyOrderPreparing = settings['notify_order_preparing'] == true;

      notifyOrderShipped = settings['notify_order_shipped'] == true;

      notifyOrderDelivered = settings['notify_order_delivered'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso.')),
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
      if (!mounted) {
        return;
      }

      setState(() {
        savingSettings = false;
      });
    }
  }

  // ==========================================================
  // SEÇÃO
  // ==========================================================

  Widget buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(child: Column(children: children)),
      ],
    );
  }

  // ==========================================================
  // ITEM DA CONFIGURAÇÃO
  // ==========================================================

  Widget buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }

  // ==========================================================
  // INFORMAÇÕES DA LOJA
  // ==========================================================

  Future<void> openStoreInformation() async {
    final storeNameDialogController = TextEditingController(
      text: storeNameController.text,
    );

    final phoneDialogController = TextEditingController(
      text: phoneController.text,
    );

    final emailDialogController = TextEditingController(
      text: emailController.text,
    );

    bool savingDialog = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Informações da loja'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: storeNameDialogController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da loja',
                          prefixIcon: Icon(Icons.store_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneDialogController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailDialogController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: savingDialog
                      ? null
                      : () {
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: savingDialog
                      ? null
                      : () async {
                          final name = storeNameDialogController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('O nome da loja é obrigatório.'),
                              ),
                            );

                            return;
                          }

                          setDialogState(() {
                            savingDialog = true;
                          });

                          try {
                            final settings = await adminSettingsService
                                .updateSettings(
                                  storeName: name,
                                  phone:
                                      phoneDialogController.text.trim().isEmpty
                                      ? null
                                      : phoneDialogController.text.trim(),
                                  email:
                                      emailDialogController.text.trim().isEmpty
                                      ? null
                                      : emailDialogController.text.trim(),
                                  notifyNewOrder: notifyNewOrder,
                                  notifyPaymentApproved: notifyPaymentApproved,
                                  notifyOrderConfirmed: notifyOrderConfirmed,
                                  notifyOrderPreparing: notifyOrderPreparing,
                                  notifyOrderShipped: notifyOrderShipped,
                                  notifyOrderDelivered: notifyOrderDelivered,
                                );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            if (mounted) {
                              setState(() {
                                storeNameController.text =
                                    settings['store_name']?.toString() ?? name;

                                phoneController.text =
                                    settings['phone']?.toString() ?? '';

                                emailController.text =
                                    settings['email']?.toString() ?? '';

                                notifyNewOrder =
                                    settings['notify_new_order'] == true;

                                notifyPaymentApproved =
                                    settings['notify_payment_approved'] == true;

                                notifyOrderConfirmed =
                                    settings['notify_order_confirmed'] == true;

                                notifyOrderPreparing =
                                    settings['notify_order_preparing'] == true;

                                notifyOrderShipped =
                                    settings['notify_order_shipped'] == true;

                                notifyOrderDelivered =
                                    settings['notify_order_delivered'] == true;
                              });
                            }

                            Navigator.pop(dialogContext, true);
                          } catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              savingDialog = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: savingDialog
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    storeNameDialogController.dispose();
    phoneDialogController.dispose();
    emailDialogController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informações da loja atualizadas.')),
      );
    }
  }

  // ==========================================================
  // NOTIFICAÇÕES AUTOMÁTICAS
  // ==========================================================

  Future<void> openNotificationSettings() async {
    bool localNewOrder = notifyNewOrder;

    bool localPaymentApproved = notifyPaymentApproved;

    bool localOrderConfirmed = notifyOrderConfirmed;

    bool localOrderPreparing = notifyOrderPreparing;

    bool localOrderShipped = notifyOrderShipped;

    bool localOrderDelivered = notifyOrderDelivered;

    bool savingDialog = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Notificações automáticas'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        value: localNewOrder,
                        onChanged: savingDialog
                            ? null
                            : (value) {
                                setDialogState(() {
                                  localNewOrder = value;
                                });
                              },
                        secondary: const Icon(Icons.shopping_bag_outlined),
                        title: const Text('Novo pedido'),
                        subtitle: const Text(
                          'Avisar quando um novo pedido for criado.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: localPaymentApproved,
                        onChanged: savingDialog
                            ? null
                            : (value) {
                                setDialogState(() {
                                  localPaymentApproved = value;
                                });
                              },
                        secondary: const Icon(Icons.check_circle_outline),
                        title: const Text('Pagamento aprovado'),
                        subtitle: const Text(
                          'Avisar quando o pagamento for aprovado.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: localOrderConfirmed,
                        onChanged: savingDialog
                            ? null
                            : (value) {
                                setDialogState(() {
                                  localOrderConfirmed = value;
                                });
                              },
                        secondary: const Icon(Icons.verified_outlined),
                        title: const Text('Pedido confirmado'),
                        subtitle: const Text(
                          'Avisar quando o pedido for confirmado.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: localOrderPreparing,
                        onChanged: savingDialog
                            ? null
                            : (value) {
                                setDialogState(() {
                                  localOrderPreparing = value;
                                });
                              },
                        secondary: const Icon(Icons.build_circle_outlined),
                        title: const Text('Pedido em preparação'),
                        subtitle: const Text(
                          'Avisar quando o pedido entrar em preparação.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: localOrderShipped,
                        onChanged: savingDialog
                            ? null
                            : (value) {
                                setDialogState(() {
                                  localOrderShipped = value;
                                });
                              },
                        secondary: const Icon(Icons.local_shipping_outlined),
                        title: const Text('Pedido enviado'),
                        subtitle: const Text(
                          'Avisar quando o pedido for enviado.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: localOrderDelivered,
                        onChanged: savingDialog
                            ? null
                            : (value) {
                                setDialogState(() {
                                  localOrderDelivered = value;
                                });
                              },
                        secondary: const Icon(Icons.inventory_outlined),
                        title: const Text('Pedido entregue'),
                        subtitle: const Text(
                          'Avisar quando a entrega for concluída.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: savingDialog
                      ? null
                      : () {
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: savingDialog
                      ? null
                      : () async {
                          setDialogState(() {
                            savingDialog = true;
                          });

                          try {
                            final settings = await adminSettingsService
                                .updateSettings(
                                  storeName: storeNameController.text.trim(),
                                  phone: phoneController.text.trim().isEmpty
                                      ? null
                                      : phoneController.text.trim(),
                                  email: emailController.text.trim().isEmpty
                                      ? null
                                      : emailController.text.trim(),
                                  notifyNewOrder: localNewOrder,
                                  notifyPaymentApproved: localPaymentApproved,
                                  notifyOrderConfirmed: localOrderConfirmed,
                                  notifyOrderPreparing: localOrderPreparing,
                                  notifyOrderShipped: localOrderShipped,
                                  notifyOrderDelivered: localOrderDelivered,
                                );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            if (mounted) {
                              setState(() {
                                notifyNewOrder =
                                    settings['notify_new_order'] == true;

                                notifyPaymentApproved =
                                    settings['notify_payment_approved'] == true;

                                notifyOrderConfirmed =
                                    settings['notify_order_confirmed'] == true;

                                notifyOrderPreparing =
                                    settings['notify_order_preparing'] == true;

                                notifyOrderShipped =
                                    settings['notify_order_shipped'] == true;

                                notifyOrderDelivered =
                                    settings['notify_order_delivered'] == true;
                              });
                            }

                            Navigator.pop(dialogContext, true);
                          } catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              savingDialog = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: savingDialog
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar notificações'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações de notificações atualizadas.'),
        ),
      );
    }
  }

  // ==========================================================
  // ALTERAR DADOS DO ADMINISTRADOR
  // ==========================================================

  Future<void> openAdminProfile() async {
    final nameController = TextEditingController(text: adminName);

    final emailControllerDialog = TextEditingController(text: adminEmail);

    final formKey = GlobalKey<FormState>();

    bool savingDialog = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Dados da conta administrativa'),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (text.isEmpty) {
                              return 'Informe o nome.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailControllerDialog,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (text.isEmpty) {
                              return 'Informe o e-mail.';
                            }

                            if (!text.contains('@') || !text.contains('.')) {
                              return 'Informe um e-mail válido.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: savingDialog
                      ? null
                      : () {
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: savingDialog
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            savingDialog = true;
                          });

                          final name = nameController.text.trim();

                          final email = emailControllerDialog.text.trim();

                          try {
                            final user = await authService.updateAdminProfile(
                              name: name,
                              email: email,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            if (mounted) {
                              setState(() {
                                adminName = user['name']?.toString() ?? name;

                                adminEmail = user['email']?.toString() ?? email;
                              });
                            }

                            Navigator.pop(dialogContext, true);
                          } catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              savingDialog = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: savingDialog
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailControllerDialog.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados da conta atualizados com sucesso.'),
        ),
      );
    }
  }

  // ==========================================================
  // ALTERAR SENHA DO ADMINISTRADOR
  // ==========================================================

  Future<void> openAdminPassword() async {
    final currentPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;

    bool obscureNew = true;

    bool obscureConfirm = true;

    bool savingDialog = false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Alterar senha administrativa'),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Senha atual',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureCurrent = !obscureCurrent;
                                });
                              },
                              icon: Icon(
                                obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Informe a senha atual.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Nova senha',
                            prefixIcon: const Icon(Icons.password_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureNew = !obscureNew;
                                });
                              },
                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                            helperText: 'Mínimo de 6 caracteres.',
                          ),
                          validator: (value) {
                            final text = value ?? '';

                            if (text.isEmpty) {
                              return 'Informe a nova senha.';
                            }

                            if (text.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar nova senha',
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureConfirm = !obscureConfirm;
                                });
                              },
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Confirme a nova senha.';
                            }

                            if (value != newPasswordController.text) {
                              return 'As senhas não coincidem.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: savingDialog
                      ? null
                      : () {
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: savingDialog
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            savingDialog = true;
                          });

                          try {
                            await authService.changeAdminPassword(
                              currentPassword: currentPasswordController.text,
                              newPassword: newPasswordController.text,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(dialogContext, true);
                          } catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              savingDialog = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: savingDialog
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Alterar senha'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso.')),
      );
    }
  }

  // ==========================================================
  // PLACEHOLDER
  // ==========================================================

  void showNotAvailable(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title ainda será configurado.')));
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final isProcessing =
        loadingSettings || savingSettings || loadingAdminAccount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isProcessing
                ? null
                : () {
                    loadSettings();
                    loadAdminAccount();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ==================================================
                          // TÍTULO
                          // ==================================================
                          const Text(
                            'Configurações da administração',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Gerencie as configurações e integrações do EBD V2.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // DADOS DA LOJA
                          // ==================================================
                          buildSection(
                            title: 'Dados da loja',
                            children: [
                              buildSettingTile(
                                icon: Icons.store_outlined,
                                title: 'Informações da loja',
                                subtitle:
                                    '${storeNameController.text.isEmpty ? 'EBD V2' : storeNameController.text} • ${phoneController.text.isEmpty ? 'Telefone não informado' : phoneController.text}',
                                onTap: isProcessing
                                    ? null
                                    : openStoreInformation,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // NOTIFICAÇÕES
                          // ==================================================
                          buildSection(
                            title: 'Notificações',
                            children: [
                              buildSettingTile(
                                icon: Icons.notifications_outlined,
                                title: 'Notificações automáticas',
                                subtitle:
                                    'Pedidos: ${[notifyNewOrder, notifyPaymentApproved, notifyOrderConfirmed, notifyOrderPreparing, notifyOrderShipped, notifyOrderDelivered].where((value) => value).length}/6 ativadas',
                                onTap: isProcessing
                                    ? null
                                    : openNotificationSettings,
                              ),

                              const Divider(height: 1),

                              buildSettingTile(
                                icon: Icons.chat_outlined,
                                title: 'WhatsApp',
                                subtitle: 'Integração com a WhatsApp Cloud API',
                                onTap: () {
                                  showNotAvailable('WhatsApp');
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // PAGAMENTOS
                          // ==================================================
                          buildSection(
                            title: 'Pagamentos',
                            children: [
                              buildSettingTile(
                                icon: Icons.payments_outlined,
                                title: 'Mercado Pago',
                                subtitle:
                                    'Configuração da integração de pagamentos',
                                onTap: () {
                                  showNotAvailable('Mercado Pago');
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // IMAGENS
                          // ==================================================
                          buildSection(
                            title: 'Imagens',
                            children: [
                              buildSettingTile(
                                icon: Icons.cloud_outlined,
                                title: 'Cloudinary',
                                subtitle:
                                    'Armazenamento das imagens dos produtos',
                                onTap: isProcessing
                                    ? null
                                    : () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AdminCloudinaryScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // CONTA ADMINISTRATIVA
                          // ==================================================
                          buildSection(
                            title: 'Conta administrativa',
                            children: [
                              buildSettingTile(
                                icon: Icons.manage_accounts_outlined,
                                title: 'Dados da conta',
                                subtitle: loadingAdminAccount
                                    ? 'Carregando dados...'
                                    : '${adminName.isEmpty ? 'Nome não informado' : adminName} • ${adminEmail.isEmpty ? 'E-mail não informado' : adminEmail}',
                                onTap: isProcessing ? null : openAdminProfile,
                              ),

                              const Divider(height: 1),

                              buildSettingTile(
                                icon: Icons.lock_outline,
                                title: 'Alterar senha',
                                subtitle:
                                    'Alterar a senha da conta administrativa',
                                onTap: isProcessing ? null : openAdminPassword,
                              ),

                              const Divider(height: 1),

                              buildSettingTile(
                                icon: Icons.logout,
                                title: 'Sair',
                                subtitle: 'Encerrar a sessão administrativa',
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // RESPONSIVIDADE
                          // ==================================================
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    isWide
                                        ? Icons.desktop_windows_outlined
                                        : Icons.smartphone_outlined,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isWide
                                          ? 'Painel otimizado para desktop e telas maiores.'
                                          : 'Painel otimizado para celular e telas menores.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
