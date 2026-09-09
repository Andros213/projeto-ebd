import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class AdminSettingsService {
  final TokenStorage tokenStorage = TokenStorage();

  // ==========================================================
  // BUSCAR CONFIGURAÇÕES
  // ==========================================================

  Future<Map<String, dynamic>> getSettings() async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/settings'),

      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['settings']);
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(data['message'] ?? 'Erro ao carregar configurações');
  }

  // ==========================================================
  // ATUALIZAR CONFIGURAÇÕES
  // ==========================================================

  Future<Map<String, dynamic>> updateSettings({
    required String storeName,
    String? phone,
    String? email,

    required bool notifyNewOrder,
    required bool notifyPaymentApproved,
    required bool notifyOrderConfirmed,
    required bool notifyOrderPreparing,
    required bool notifyOrderShipped,
    required bool notifyOrderDelivered,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/settings'),

      headers: {
        'Content-Type': 'application/json',

        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({
        'storeName': storeName,

        'phone': phone,

        'email': email,

        'notifyNewOrder': notifyNewOrder,

        'notifyPaymentApproved': notifyPaymentApproved,

        'notifyOrderConfirmed': notifyOrderConfirmed,

        'notifyOrderPreparing': notifyOrderPreparing,

        'notifyOrderShipped': notifyOrderShipped,

        'notifyOrderDelivered': notifyOrderDelivered,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['settings']);
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(data['message'] ?? 'Erro ao atualizar configurações');
  }
}
