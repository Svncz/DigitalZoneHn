import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id;
  String name;
  String description;
  double price;
  String imageUrl;
  bool promo;
  String category;
  bool available;
  DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.promo = false,
    this.category = 'Video',
    this.available = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'promo': promo,
      'category': category,
      'available': available,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      promo: map['promo'] ?? false,
      category: map['category'] ?? 'Video',
      available: map['available'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
