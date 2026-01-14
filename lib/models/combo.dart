import 'package:cloud_firestore/cloud_firestore.dart';

class Combo {
  String id;
  String name;
  String description;
  double price;
  List<String> productIds; // IDs of products in the combo
  String imageUrl;
  bool available;

  Combo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.productIds,
    this.imageUrl = '',
    this.available = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'productIds': productIds,
      'imageUrl': imageUrl,
      'available': available,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Combo.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Combo(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      productIds: List<String>.from(data['productIds'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      available: data['available'] ?? true,
    );
  }
}
