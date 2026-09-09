class ProductModel {
  final int id;
  final String name;
  final String type;
  final String? className;
  final String? description;
  final double price;
  final String? imageUrl;
  final int stock;
  final bool active;

  ProductModel({
    required this.id,
    required this.name,
    required this.type,
    this.className,
    this.description,
    required this.price,
    this.imageUrl,
    required this.stock,
    required this.active,
  });


  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      className: json['class'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'],
      stock: json['stock'],
      active: json['active'],
    );
  }
}