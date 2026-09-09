import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';


class AdminUserService {
  final TokenStorage tokenStorage =
      TokenStorage();


  // ==========================================================
  // LISTAR CLIENTES
  // ==========================================================

  Future<List<Map<String, dynamic>>> listClients() async {
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
        '${ApiConfig.baseUrl}/admin/clients',
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

      final clients =
          data['clients'] as List;


      return clients
          .map(
            (client) =>
                Map<String, dynamic>.from(
              client,
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
          'Erro ao carregar clientes',
    );
  }


  // ==========================================================
  // DETALHES DO CLIENTE
  // ==========================================================

  Future<Map<String, dynamic>> getClientById(
    int clientId,
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
        '${ApiConfig.baseUrl}/admin/clients/$clientId',
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
        data['client'],
      );
    }


    if (response.statusCode == 404) {
      throw Exception(
        'Cliente não encontrado',
      );
    }


    if (response.statusCode == 403) {
      throw Exception(
        'Acesso permitido apenas para administradores',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar cliente',
    );
  }
}