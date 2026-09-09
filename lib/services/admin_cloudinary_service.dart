import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class AdminCloudinaryService {
  final TokenStorage tokenStorage = TokenStorage();

  // ==========================================================
  // TOKEN
  // ==========================================================

  Future<String> _getToken() async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    return token;
  }

  // ==========================================================
  // RESUMO DO CLOUDINARY
  // ==========================================================

  Future<Map<String, dynamic>> getSummary() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/cloudinary/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['cloudinary'] ?? {});
    }

    if (response.statusCode == 401) {
      throw Exception('Sessão expirada ou token inválido');
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(
      data['message'] ?? 'Erro ao carregar informações do Cloudinary',
    );
  }

  // ==========================================================
  // LISTAR IMAGENS
  // ==========================================================

  Future<Map<String, dynamic>> getImages({
    String? nextCursor,
    int maxResults = 100,
  }) async {
    final token = await _getToken();

    final queryParameters = <String, String>{
      'maxResults': maxResults.toString(),
    };

    if (nextCursor != null && nextCursor.isNotEmpty) {
      queryParameters['nextCursor'] = nextCursor;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/admin/cloudinary/images',
    ).replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'images': data['images'] is List
            ? List<Map<String, dynamic>>.from(
                (data['images'] as List).map(
                  (item) => Map<String, dynamic>.from(item),
                ),
              )
            : <Map<String, dynamic>>[],
        'nextCursor': data['nextCursor']?.toString(),
      };
    }

    if (response.statusCode == 401) {
      throw Exception('Sessão expirada ou token inválido');
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(
      data['message'] ?? 'Erro ao carregar imagens do Cloudinary',
    );
  }

  // ==========================================================
  // EXCLUIR IMAGEM
  // ==========================================================

  Future<void> deleteImage({required String publicId}) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/cloudinary/images'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'publicId': publicId}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception('Sessão expirada ou token inválido');
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    if (response.statusCode == 409) {
      throw Exception(
        data['message'] ?? 'Esta imagem está vinculada a um produto.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(data['message'] ?? 'Imagem não encontrada.');
    }

    throw Exception(data['message'] ?? 'Erro ao excluir imagem do Cloudinary');
  }
}
