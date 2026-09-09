import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';


class ProductsScreen extends StatefulWidget {

  const ProductsScreen({super.key});


  @override
  State<ProductsScreen> createState() => _ProductsScreenState();

}



class _ProductsScreenState extends State<ProductsScreen> {


  final ProductService service = ProductService();


  late Future<List<ProductModel>> products;



  @override
  void initState() {

    super.initState();

    products = service.getProducts();

  }



  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Produtos EBD'
        ),
      ),


      body: FutureBuilder<List<ProductModel>>(

        future: products,


        builder: (context, snapshot) {


          if(snapshot.connectionState == ConnectionState.waiting){

            return const Center(
              child: CircularProgressIndicator(),
            );

          }



          if(snapshot.hasError){

            return Center(

              child: Text(
                'Erro: ${snapshot.error}'
              ),

            );

          }



          final items = snapshot.data ?? [];



          return ListView.builder(

            itemCount: items.length,


            itemBuilder: (context,index){


              final product = items[index];


              return Card(

                child: ListTile(

                  title: Text(product.name),


                  subtitle: Text(
                    '${product.type} | Estoque: ${product.stock}'
                  ),


                  trailing: Text(
                    'R\$ ${product.price.toStringAsFixed(2)}'
                  ),

                ),

              );


            },

          );


        },

      ),

    );


  }


}