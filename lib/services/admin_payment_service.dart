import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';


class AdminPaymentService {
  final TokenStorage tokenStorage =
      TokenStorage();


  // ==========================================================
  // LISTAR PAGAMENTOS
  // ==========================================================

  Future<List<Map<String, dynamic>>> listPayments() async {
    final token =
        await tokenStorage.getToken();


    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/payments',
      ),

      headers: {
        'Authorization':
            'Bearer $token',
      },
    );


    final data =
        jsonDecode(response.body);


    if (
      response.statusCode == 200 &&
      data['success'] == true
    ) {

      final payments =
          data['payments'] as List;


      return payments
          .map(
            (payment) =>
                Map<String, dynamic>.from(
              payment,
            ),
          )
          .toList();
    }


    if (response.statusCode == 403) {
      throw Exception(
        'Acesso permitido apenas para administradores',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar pagamentos',
    );
  }


  // ==========================================================
  // DETALHE DO PAGAMENTO
  // ==========================================================

  Future<Map<String, dynamic>> getPaymentById(
    int paymentId,
  ) async {

    final token =
        await tokenStorage.getToken();


    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/payments/$paymentId',
      ),

      headers: {
        'Authorization':
            'Bearer $token',
      },
    );


    final data =
        jsonDecode(response.body);


    if (
      response.statusCode == 200 &&
      data['success'] == true
    ) {

      return Map<String, dynamic>.from(
        data['payment'],
      );
    }


    if (response.statusCode == 404) {
      throw Exception(
        'Pagamento não encontrado',
      );
    }


    if (response.statusCode == 403) {
      throw Exception(
        'Acesso permitido apenas para administradores',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar pagamento',
    );
  }
}