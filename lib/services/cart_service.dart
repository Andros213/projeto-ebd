import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class CartService {
  final TokenStorage tokenStorage = TokenStorage();

  Future<void> addToCart({
    required int productId,
    required int quantity,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuario nao autenticado');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cart'),

      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({'productId': productId, 'quantity': quantity}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return;
    }

    throw Exception(data['message'] ?? 'Erro ao adicionar produto ao carrinho');
  }

  Future<Map<String, dynamic>> getCart() async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuario nao autenticado');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cart'),

      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['cart'];
    }

    throw Exception(data['message'] ?? 'Erro ao carregar o carrinho');
  }

  Future<void> updateCartItem({
    required int productId,
    required int quantity,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuario nao autenticado');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/cart/$productId'),

      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({'quantity': quantity}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw Exception(data['message'] ?? 'Erro ao atualizar quantidade');
  }

  Future<void> removeFromCart({required int productId}) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuario nao autenticado');
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/cart/$productId'),

      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw Exception(data['message'] ?? 'Erro ao remover produto do carrinho');
  }
}
