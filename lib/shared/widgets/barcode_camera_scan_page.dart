import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

bool get supportsCameraBarcodeScanning {
  if (kIsWeb) {
    return true;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => true,
    TargetPlatform.iOS => true,
    TargetPlatform.macOS => true,
    _ => false,
  };
}

Future<String?> openBarcodeCameraScanner(
  BuildContext context, {
  String title = 'Kamera ile Oku',
  String subtitle =
      'Barkodu kameraya gosterin. Ilk bulunan deger otomatik secilir.',
}) async {
  if (!supportsCameraBarcodeScanning) {
    return null;
  }

  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (context) {
        return BarcodeCameraScanPage(title: title, subtitle: subtitle);
      },
      fullscreenDialog: true,
    ),
  );
}

class BarcodeCameraScanPage extends StatefulWidget {
  const BarcodeCameraScanPage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<BarcodeCameraScanPage> createState() => _BarcodeCameraScanPageState();
}

class _BarcodeCameraScanPageState extends State<BarcodeCameraScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _didPop = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_didPop) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _didPop = true;
      Navigator.of(context).pop(rawValue);
      return;
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) {
      return;
    }

    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            onPressed: _toggleTorch,
            tooltip: _isTorchOn ? 'Feneri kapat' : 'Feneri ac',
            icon: Icon(
              _isTorchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(controller: _controller, onDetect: _handleDetection),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 264,
                height: 264,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(96),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xCC101316),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Okuma olmuyorsa ortami aydinlatin ve barkodu kutu icinde tutun.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
