import 'package:flutter/material.dart';
import 'models/product.dart';
import 'models/invoice.dart';
import 'services/printer_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dalil Invoice Printer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Blue color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFF1E3A8A,
        ), // Dark blue background
        cardTheme: CardThemeData(
          color: Colors.grey[100], // Light grey/white for cards
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final List<Product> _products = [
    Product(id: '1', name: 'Aero Bleu', price: 250.000),
    Product(id: '2', name: 'Burger Deluxe', price: 15.500),
    Product(id: '3', name: 'Pizza Margherita', price: 12.000),
    Product(id: '4', name: 'Chicken Shawarma', price: 8.500),
    Product(id: '5', name: 'Falafel Wrap', price: 6.000),
    Product(id: '6', name: 'Caesar Salad', price: 10.000),
  ];

  final Customer _defaultCustomer = Customer(
    name: 'Sundus',
    phone: '+9651656246',
    email: 'sundusalfaresi@gmail.com',
  );

  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _initializePrinter();
  }

  Future<void> _initializePrinter() async {
    bool initialized = await PrinterService.initPrinter();
    if (!initialized && mounted) {
      // Don't show error on startup - printer might not be available on emulator
      // Error will be shown when user tries to print
      print(
        'Printer not available - this is expected on emulator or non-Sunmi devices',
      );
    }
  }

  void _updateQuantity(Product product, int quantity) {
    setState(() {
      product.quantity = quantity;
    });
  }

  List<Product> get _selectedProducts {
    return _products.where((p) => p.quantity > 0).toList();
  }

  double get _subtotal {
    return _selectedProducts.fold(0.0, (sum, p) => sum + p.total);
  }

  double get _total {
    return _subtotal + 2.0; // Delivery fee
  }

  Future<void> _printInvoice() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      // Generate invoice
      final invoice = Invoice(
        invoiceNumber: DateTime.now().millisecondsSinceEpoch.toString(),
        customer: _defaultCustomer,
        orderId: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
        paymentMethod: 'Knet',
        products: List.from(_selectedProducts),
        deliveryFee: 2.0,
      );

      // Print invoice
      await PrinterService.printInvoice(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice printed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dalil Invoice Printer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Product List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.price.toStringAsFixed(3)} KWD',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quantity Controls
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: product.quantity > 0
                                  ? () => _updateQuantity(
                                      product,
                                      product.quantity - 1,
                                    )
                                  : null,
                              color: const Color(0xFF1E3A8A),
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '${product.quantity}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _updateQuantity(
                                product,
                                product.quantity + 1,
                              ),
                              color: const Color(0xFF1E3A8A),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Summary and Print Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_selectedProducts.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                      Text(
                        '${_subtotal.toStringAsFixed(3)} KWD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Fee:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '2.000 KWD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        '${_total.toStringAsFixed(3)} KWD',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPrinting ? null : _printInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isPrinting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.print, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Print Invoice',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
