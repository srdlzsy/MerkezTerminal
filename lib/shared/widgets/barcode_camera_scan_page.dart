import 'dart:convert';

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
  bool qrOnly = false,
}) async {
  if (!supportsCameraBarcodeScanning) {
    return null;
  }

  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (context) {
        return BarcodeCameraScanPage(
          title: title,
          subtitle: subtitle,
          qrOnly: qrOnly,
        );
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
    required this.qrOnly,
  });

  final String title;
  final String subtitle;
  final bool qrOnly;

  @override
  State<BarcodeCameraScanPage> createState() => _BarcodeCameraScanPageState();
}

class _BarcodeCameraScanPageState extends State<BarcodeCameraScanPage> {
  late final MobileScannerController _controller;
  bool _didPop = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: widget.qrOnly
          ? const <BarcodeFormat>[BarcodeFormat.qrCode]
          : const <BarcodeFormat>[],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_didPop) {
      return;
    }

    for (final barcode in capture.barcodes) {
      debugPrint(
        'Barcode detected format=${barcode.format.name} '
        'rawLength=${barcode.rawValue?.length ?? 0} '
        'displayLength=${barcode.displayValue?.length ?? 0} '
        'bytes=${barcode.rawBytes?.length ?? 0}',
      );
      final rawValue = _barcodeValue(barcode)?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _didPop = true;
      await _controller.stop();
      if (!mounted) {
        return;
      }
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

  String? _barcodeValue(Barcode barcode) {
    final rawValue = barcode.rawValue?.trim();
    if (rawValue != null && rawValue.isNotEmpty) {
      return rawValue;
    }

    final displayValue = barcode.displayValue?.trim();
    if (displayValue != null && displayValue.isNotEmpty) {
      return displayValue;
    }

    final rawBytes = barcode.rawBytes;
    if (rawBytes == null || rawBytes.isEmpty) {
      return null;
    }

    return _decodeBarcodeBytes(rawBytes);
  }

  String? _decodeBarcodeBytes(Uint8List rawBytes) {
    for (final decoder in const <Encoding>[utf8, latin1]) {
      try {
        final decoded = decoder.decode(rawBytes).trim();
        if (decoded.isNotEmpty) {
          return decoded;
        }
      } on FormatException {
        continue;
      }
    }

    return null;
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
