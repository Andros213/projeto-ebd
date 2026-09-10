import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class PaymentService {
  final TokenStorage tokenStorage = TokenStorage();

  Future<Map<String, dynamic>> createPreference({required int orderId}) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuario nao autenticado');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data['preference']);
    }

    throw Exception(data['message'] ?? 'Erro ao criar pagamento');
  }

  Future<Map<String, dynamic>> processPayment({
    required int orderId,
    required Map<String, dynamic> paymentData,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuario nao autenticado');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/$orderId/process'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(paymentData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'Erro ao processar pagamento');
  }
}
