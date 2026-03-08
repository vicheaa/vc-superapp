class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl; // Can be an emoji for this demo

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
