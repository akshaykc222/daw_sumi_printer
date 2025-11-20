class Product {
  final String id;
  final String name;
  final double price;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 0,
  });

  double get total => price * quantity;
}

