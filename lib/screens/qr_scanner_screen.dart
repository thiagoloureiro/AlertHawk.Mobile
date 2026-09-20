import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
      if (values.length != 7) {
        throw Exception(
            'Invalid QR code format, expected 7 values, got ${values.length}');
      }

      final settings = {
        'monitoring_api_url': values[0],
        'auth_api_url': values[1],
        'notification_api_url': values[2],
        'metrics_api_url': values[3],
        'azure_ad_tenant': values[4],
        'azure_ad_client_id': values[5],
        'auth_api_key': values[6],
      };

      _hasScanned = true;
      Navigator.of(context).pop(settings);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid QR code format. Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Text(
                'Point the camera at your AlertHawk configuration QR code',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
