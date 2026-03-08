import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/product.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  static const List<Product> _mockProducts = [
    Product(id: 'p1', name: 'Wireless Headphones', price: 99.99, imageUrl: '🎧'),
    Product(id: 'p2', name: 'Smart Watch', price: 199.50, imageUrl: '⌚️'),
    Product(id: 'p3', name: 'Mechanical Keyboard', price: 149.00, imageUrl: '⌨️'),
    Product(id: 'p4', name: 'Gaming Mouse', price: 59.99, imageUrl: '🖱️'),
    Product(id: 'p5', name: '4K Monitor', price: 349.99, imageUrl: '🖥️'),
    Product(id: 'p6', name: 'USB-C Hub', price: 29.99, imageUrl: '🔌'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'View React Cart',
            onPressed: () {
              // Open the web_app/dist cart without a specific product insertion
              context.push('/webview', extra: 'web_app');
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _mockProducts.length,
        itemBuilder: (context, index) {
          final product = _mockProducts[index];
          return _ProductCard(product: product);
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  void _addToCart(BuildContext context) {
    // Navigate to the webview and pass the product to be injected into React
    context.push('/webview', extra: {
      'type': 'web_app',
      'product': product.toJson(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Text(
                  product.imageUrl,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _addToCart(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
