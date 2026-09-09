import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ChurchService {
  Future<List<Map<String, dynamic>>> getChurches() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/churches'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final churches = data['churches'];

      if (churches is List) {
        return churches
            .map((church) => Map<String, dynamic>.from(church))
            .toList();
      }
    }

    throw Exception(data['message'] ?? 'Erro ao carregar igrejas');
  }
}
