import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (!_hasScanned) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        if (barcode.rawValue != null) {
          _processQRCode(barcode.rawValue!);
          break;
        }
      }
    }
  }

  void _processQRCode(String code) {
    try {
      final values = code.split(';');
      if (values.length != 6) {
        throw Exception('Invalid QR code format');
      }

      final configuration = {
        'monitoring_api_url': values[0],
        'auth_api_url': values[1],
        'notification_api_url': values[2],
        'azure_ad_tenant': values[3],
        'azure_ad_client_id': values[4],
        'auth_api_key': values[5],
      };

      _hasScanned = true;
      Navigator.of(context).pop(configuration);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code format')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
