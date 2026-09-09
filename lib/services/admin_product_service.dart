import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import 'token_storage.dart';

class AdminProductService {
  final TokenStorage tokenStorage = TokenStorage();

  // ==========================================================
  // LISTAR PRODUTOS
  // ==========================================================

  Future<List<Map<String, dynamic>>> listAllProducts() async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/products'),

      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final products = data['products'] as List;

      return products
          .map((product) => Map<String, dynamic>.from(product))
          .toList();
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(data['message'] ?? 'Erro ao carregar produtos');
  }

  // ==========================================================
  // ENVIAR IMAGEM DO PRODUTO
  // ==========================================================

  Future<Map<String, dynamic>> uploadProductImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final request = http.MultipartRequest(
      'POST',

      Uri.parse('${ApiConfig.baseUrl}/admin/products/upload-image'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    String mimeType = 'jpeg';

    final lowerFileName = fileName.toLowerCase();

    if (lowerFileName.endsWith('.png')) {
      mimeType = 'png';
    } else if (lowerFileName.endsWith('.webp')) {
      mimeType = 'webp';
    } else if (lowerFileName.endsWith('.gif')) {
      mimeType = 'gif';
    } else if (lowerFileName.endsWith('.bmp')) {
      mimeType = 'bmp';
    } else if (lowerFileName.endsWith('.avif')) {
      mimeType = 'avif';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType('image', mimeType),
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data['image']);
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(data['message'] ?? 'Erro ao enviar imagem');
  }

  // ==========================================================
  // CRIAR PRODUTO
  // ==========================================================

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String type,
    String? className,
    String? description,
    required double price,
    String? imageUrl,
    required int stock,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/products'),

      headers: {
        'Content-Type': 'application/json',

        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({
        'name': name,
        'type': type,
        'class': className,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'stock': stock,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data['product']);
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(data['message'] ?? 'Erro ao cadastrar produto');
  }

  // ==========================================================
  // ATUALIZAR PRODUTO
  // ==========================================================

  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required String type,
    String? className,
    String? description,
    required double price,
    String? imageUrl,
    required int stock,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/products/$productId'),

      headers: {
        'Content-Type': 'application/json',

        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({
        'name': name,
        'type': type,
        'class': className,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'stock': stock,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['product']);
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(data['message'] ?? 'Erro ao atualizar produto');
  }

  // ==========================================================
  // ATIVAR / DESATIVAR
  // ==========================================================

  Future<Map<String, dynamic>> setProductActive({
    required int productId,
    required bool active,
  }) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/admin/products/$productId/active'),

      headers: {
        'Content-Type': 'application/json',

        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({'active': active}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['product']);
    }

    if (response.statusCode == 403) {
      throw Exception('Acesso permitido apenas para administradores');
    }

    throw Exception(data['message'] ?? 'Erro ao alterar status do produto');
  }

  // ==========================================================
  // REMOVER PRODUTO
  // ==========================================================

  Future<void> deleteProduct({required int productId}) async {
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/products/$productId'),

      headers: {'Authorization': 'Bearer $token'},
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

    if (response.statusCode == 404) {
      throw Exception(data['message'] ?? 'Produto não encontrado');
    }

    if (response.statusCode == 409) {
      throw Exception(
        data['message'] ??
            'Este produto não pode ser removido porque possui pedidos registrados.',
      );
    }

    throw Exception(data['message'] ?? 'Erro ao remover produto');
  }
}
