import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';


class AdminOrderService {
  final TokenStorage tokenStorage =
      TokenStorage();


  Future<List<Map<String, dynamic>>> listAllOrders() async {
    final token =
        await tokenStorage.getToken();


    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/orders',
      ),

      headers: {
        'Authorization':
            'Bearer $token',
      },
    );


    final data =
        jsonDecode(response.body);


    if (response.statusCode == 200 &&
        data['success'] == true) {

      final orders =
          data['orders'] as List;


      return orders
          .map(
            (order) =>
                Map<String, dynamic>.from(
              order,
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
          'Erro ao carregar pedidos',
    );
  }


  Future<Map<String, dynamic>> getOrderById(
    int orderId,
  ) async {
    final token =
        await tokenStorage.getToken();


    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/orders/$orderId',
      ),

      headers: {
        'Authorization':
            'Bearer $token',
      },
    );


    final data =
        jsonDecode(response.body);


    if (response.statusCode == 200 &&
        data['success'] == true) {

      return Map<String, dynamic>.from(
        data['order'],
      );
    }


    if (response.statusCode == 403) {
      throw Exception(
        'Acesso permitido apenas para administradores',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar pedido',
    );
  }


  Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final token =
        await tokenStorage.getToken();


    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response = await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/orders/$orderId/status',
      ),

      headers: {
        'Authorization':
            'Bearer $token',

        'Content-Type':
            'application/json',
      },

      body: jsonEncode({
        'status': status,
      }),
    );


    final data =
        jsonDecode(response.body);


    if (response.statusCode == 200 &&
        data['success'] == true) {

      return Map<String, dynamic>.from(
        data['order'],
      );
    }


    if (response.statusCode == 403) {
      throw Exception(
        'Acesso permitido apenas para administradores',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao atualizar pedido',
    );
  }
}