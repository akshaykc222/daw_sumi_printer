import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import '../models/invoice.dart';

class PrinterService {
  static final SunmiPrinterPlus _printer = SunmiPrinterPlus();

  static Future<bool> initPrinter() async {
    try {
      // Try to get printer status to check if printer is available
      // This will fail on emulator but that's expected
      try {
        await _printer.getStatus(); // This will bind the printer
        return true;
      } catch (e) {
        // Printer not available (expected on emulator)
        print('Printer not available: $e');
        return false;
      }
    } catch (e) {
      print('Error initializing printer: $e');
      return false;
    }
  }

  static Future<void> printInvoice(Invoice invoice) async {
    try {
      // Try to bind printer by getting status first
      // This initializes the native printer service
      try {
        await _printer.getStatus();
      } catch (e) {
        throw Exception(
          'Printer not available. Please ensure you are running on a Sunmi device with a printer connected.',
        );
      }

      // Header - centered and bold
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Invoice\n',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.CENTER,
            bold: true,
            fontSize: 20,
          ),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Invoice #: ${invoice.invoiceNumber}\n\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER, fontSize: 14),
        ),
      );

      // Customer Information
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Customer Information\n',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.LEFT,
            bold: true,
            fontSize: 14,
          ),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Name: ${invoice.customer.name}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Phone: ${invoice.customer.phone}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Email: ${invoice.customer.email}\n\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );

      // Order Information
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Order Information\n',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.LEFT,
            bold: true,
            fontSize: 14,
          ),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Order ID: ${invoice.orderId}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Date: ${_formatDate(invoice.dateTime)}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Time: ${_formatTime(invoice.dateTime)}\n\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );

      // Payment Method
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: '${'-' * 32}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER, fontSize: 12),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Payment Method: ${invoice.paymentMethod}\n\n',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.CENTER,
            fontSize: 14,
          ),
        ),
      );

      // Product Table Header - using text instead of printRow to avoid black background
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Product        Qty    Price      Total\n',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.LEFT,
            bold: true,
            fontSize: 12,
          ),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: '${'-' * 32}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );

      // Product Rows - using formatted text instead of printRow
      for (var product in invoice.products) {
        if (product.quantity > 0) {
          String name = product.name.length > 10
              ? product.name.substring(0, 10)
              : product.name;
          String qty = product.quantity.toString().padLeft(3);
          String price = _formatCurrency(product.price).padLeft(10);
          String total = _formatCurrency(product.total).padLeft(10);
          await _printer.printCustomText(
            sunmiText: SunmiText(
              text: '${name.padRight(14)}$qty$price$total\n',
              style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
            ),
          );
        }
      }

      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: '${'-' * 32}\n\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );

      // Summary
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Subtotal: ${_formatCurrency(invoice.subtotal)}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Delivery Fee: ${_formatCurrency(invoice.deliveryFee)}\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 12),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Total: ${_formatCurrency(invoice.total)}\n\n',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.LEFT,
            fontSize: 16,
            bold: true,
          ),
        ),
      );

      // Thank you message
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Thank you for your purchase!\n\n',
          style: SunmiTextStyle(
            align: SunmiPrintAlign.CENTER,
            bold: true,
            fontSize: 14,
          ),
        ),
      );

      // Barcode
      await _printer.printBarcode(
        invoice.invoiceNumber,
        style: SunmiBarcodeStyle(
          type: SunmiBarcodeType.CODE128,
          height: 80,
          align: SunmiPrintAlign.CENTER,
          textPos: SunmiBarcodeTextPos.TEXT_UNDER,
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: '${invoice.invoiceNumber}\n\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
        ),
      );

      // Footer
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Dalil\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'All Rights Reserved © 2025\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
        ),
      );
      await _printer.printCustomText(
        sunmiText: SunmiText(
          text: 'Dalil.net • support@Dalil.net\n\n',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
        ),
      );

      // Cut paper
      await _printer.cutPaper();
    } catch (e) {
      print('Error printing invoice: $e');
      rethrow;
    }
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(3)} KWD';
  }
}
