import 'product.dart';

class Customer {
  final String name;
  final String phone;
  final String email;

  Customer({
    required this.name,
    required this.phone,
    required this.email,
  });
}

class Invoice {
  final String invoiceNumber;
  final Customer customer;
  final String orderId;
  final DateTime dateTime;
  final String paymentMethod;
  final List<Product> products;
  final double deliveryFee;

  Invoice({
    required this.invoiceNumber,
    required this.customer,
    required this.orderId,
    required this.dateTime,
    required this.paymentMethod,
    required this.products,
    this.deliveryFee = 2.0,
  });

  double get subtotal {
    return products.fold(0.0, (sum, product) => sum + product.total);
  }

  double get total {
    return subtotal + deliveryFee;
  }
}

