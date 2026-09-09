import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class AuthService {
  final TokenStorage tokenStorage = TokenStorage();

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['user']['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('Token não recebido pelo servidor');
      }

      await tokenStorage.saveToken(token.toString());

      return token.toString();
    }

    throw Exception(data['message'] ?? 'Erro ao realizar login');
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['user']);
    }

    throw Exception(data['message'] ?? 'Erro ao obter usuário');
  }

  Future<Map<String, dynamic>> updateProfile({
    required int churchId,
    String? phone,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/me/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'churchId': churchId, 'phone': phone}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['user']);
    }

    throw Exception(data['message'] ?? 'Erro ao atualizar conta');
  }

  Future<Map<String, dynamic>> updateAdminProfile({
    required String name,
    required String email,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/me/admin-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['user']);
    }

    throw Exception(
      data['message'] ?? 'Erro ao atualizar conta administrativa',
    );
  }

  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/me/admin-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw Exception(data['message'] ?? 'Erro ao alterar senha administrativa');
  }

  Future<void> register({
    required int churchId,
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'churchId': churchId,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return;
    }

    throw Exception(data['message'] ?? 'Erro ao realizar cadastro');
  }
}
