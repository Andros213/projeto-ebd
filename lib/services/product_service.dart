import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/product_model.dart';


class ProductService {


  Future<List<ProductModel>> getProducts() async {

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products'),
    );


    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);


      List products = data['products'];


      return products
          .map((product) => ProductModel.fromJson(product))
          .toList();

    } else {

      throw Exception(
        'Erro ao carregar produtos'
      );

    }

  }

}