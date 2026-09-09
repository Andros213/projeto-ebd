import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';


class AdminDeliveryService {
  final TokenStorage tokenStorage =
      TokenStorage();


  // ==========================================================
  // LISTAR ENTREGAS
  // ==========================================================

  Future<List<Map<String, dynamic>>> listDeliveries() async {
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
        '${ApiConfig.baseUrl}/admin/deliveries',
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
      final deliveries =
          data['deliveries'] as List;

      return deliveries
          .map(
            (delivery) =>
                Map<String, dynamic>.from(
              delivery,
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
          'Erro ao carregar entregas',
    );
  }


  // ==========================================================
  // DETALHES
  // ==========================================================

  Future<Map<String, dynamic>> getDeliveryById(
    int deliveryId,
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
        '${ApiConfig.baseUrl}/admin/deliveries/$deliveryId',
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
        data['delivery'],
      );
    }


    if (response.statusCode == 404) {
      throw Exception(
        'Entrega não encontrada',
      );
    }


    if (response.statusCode == 403) {
      throw Exception(
        'Acesso permitido apenas para administradores',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar entrega',
    );
  }


  // ==========================================================
  // ALTERAR STATUS
  // ==========================================================

  Future<Map<String, dynamic>> updateDeliveryStatus({
    required int deliveryId,
    required String status,
    String? notes,
  }) async {
    final token =
        await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response =
        await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/deliveries/$deliveryId/status',
      ),

      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer $token',
      },

      body: jsonEncode({
        'status': status,
        'notes': notes,
      }),
    );


    final data =
        jsonDecode(response.body);


    if (
      response.statusCode == 200 &&
      data['success'] == true
    ) {
      return Map<String, dynamic>.from(
        data['delivery'],
      );
    }


    if (response.statusCode == 403) {
      throw Exception(
        'Acesso permitido apenas para administradores',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao atualizar entrega',
    );
  }
}