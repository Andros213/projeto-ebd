import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';


class AdminChurchService {
  final TokenStorage tokenStorage =
      TokenStorage();


  // ==========================================================
  // LISTAR IGREJAS
  // ==========================================================

  Future<List<Map<String, dynamic>>> listChurches() async {
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
        '${ApiConfig.baseUrl}/admin/churches',
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

      final churches =
          data['churches'] as List;


      return churches
          .map(
            (church) =>
                Map<String, dynamic>.from(
              church,
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
          'Erro ao carregar igrejas',
    );
  }


  // ==========================================================
  // BUSCAR IGREJA
  // ==========================================================

  Future<Map<String, dynamic>> getChurchById(
    int churchId,
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
        '${ApiConfig.baseUrl}/admin/churches/$churchId',
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
        data['church'],
      );
    }


    if (response.statusCode == 404) {
      throw Exception(
        'Igreja não encontrada',
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao carregar igreja',
    );
  }


  // ==========================================================
  // CRIAR IGREJA
  // ==========================================================

  Future<Map<String, dynamic>> createChurch(
    String name,
  ) async {

    final token =
        await tokenStorage.getToken();


    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response =
        await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/churches',
      ),

      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer $token',
      },

      body: jsonEncode({
        'name': name,
      }),
    );


    final data =
        jsonDecode(response.body);


    if (
      response.statusCode == 201 &&
      data['success'] == true
    ) {

      return Map<String, dynamic>.from(
        data['church'],
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao criar igreja',
    );
  }


  // ==========================================================
  // EDITAR IGREJA
  // ==========================================================

  Future<Map<String, dynamic>> updateChurch({
    required int churchId,
    required String name,
  }) async {

    final token =
        await tokenStorage.getToken();


    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado',
      );
    }


    final response =
        await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/churches/$churchId',
      ),

      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer $token',
      },

      body: jsonEncode({
        'name': name,
      }),
    );


    final data =
        jsonDecode(response.body);


    if (
      response.statusCode == 200 &&
      data['success'] == true
    ) {

      return Map<String, dynamic>.from(
        data['church'],
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao atualizar igreja',
    );
  }


  // ==========================================================
  // ATIVAR / DESATIVAR IGREJA
  // ==========================================================

  Future<Map<String, dynamic>> setChurchActive({
    required int churchId,
    required bool active,
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
        '${ApiConfig.baseUrl}/admin/churches/$churchId/active',
      ),

      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer $token',
      },

      body: jsonEncode({
        'active': active,
      }),
    );


    final data =
        jsonDecode(response.body);


    if (
      response.statusCode == 200 &&
      data['success'] == true
    ) {

      return Map<String, dynamic>.from(
        data['church'],
      );
    }


    throw Exception(
      data['message'] ??
          'Erro ao alterar status da igreja',
    );
  }
}