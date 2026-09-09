import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';


class OrderService {
  final TokenStorage tokenStorage = TokenStorage();


  Future<Map<String, dynamic>> createOrder() async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }


    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),

      headers: {
        'Authorization': 'Bearer $token',
      },
    );


    final data = jsonDecode(response.body);


    if (response.statusCode == 201 &&
        data['success'] == true) {
      return Map<String, dynamic>.from(
        data['order'],
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao criar pedido',
    );
  }


  Future<List<Map<String, dynamic>>> listMyOrders() async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }


    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders'),

      headers: {
        'Authorization': 'Bearer $token',
      },
    );


    final data = jsonDecode(response.body);


    if (response.statusCode == 200 &&
        data['success'] == true) {

      final orders =
          data['orders'] as List;


      return orders
          .map(
            (order) =>
                Map<String, dynamic>.from(order),
          )
          .toList();
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar pedidos',
    );
  }


  Future<Map<String, dynamic>> getMyOrderById(
    int orderId,
  ) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }


    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/orders/$orderId',
      ),

      headers: {
        'Authorization': 'Bearer $token',
      },
    );


    final data = jsonDecode(response.body);


    if (response.statusCode == 200 &&
        data['success'] == true) {

      return Map<String, dynamic>.from(
        data['order'],
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar pedido',
    );
  }
}