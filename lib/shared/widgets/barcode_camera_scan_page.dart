import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
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
  bool startWithTorch = false,
  double initialZoom = 0,
  bool showZoomControl = true,
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
          startWithTorch: startWithTorch,
          initialZoom: initialZoom,
          showZoomControl: showZoomControl,
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
    required this.startWithTorch,
    required this.initialZoom,
    required this.showZoomControl,
  });

  final String title;
  final String subtitle;
  final bool qrOnly;
  final bool startWithTorch;
  final double initialZoom;
  final bool showZoomControl;

  @override
  State<BarcodeCameraScanPage> createState() => _BarcodeCameraScanPageState();
}

class _BarcodeCameraScanPageState extends State<BarcodeCameraScanPage> {
  late final MobileScannerController _controller;
  bool _didPop = false;
  bool _didApplyInitialZoom = false;
  bool _isTorchOn = false;
  double _zoomScale = 0;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      cameraResolution: widget.qrOnly ? const Size(1280, 720) : null,
      detectionSpeed: widget.qrOnly
          ? DetectionSpeed.normal
          : DetectionSpeed.noDuplicates,
      detectionTimeoutMs: widget.qrOnly ? 120 : 250,
      formats: widget.qrOnly
          ? const <BarcodeFormat>[BarcodeFormat.qrCode]
          : const <BarcodeFormat>[],
      torchEnabled: widget.startWithTorch,
    );
    _isTorchOn = widget.startWithTorch;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final scannerState = _controller.value;
    final isTorchOn = scannerState.torchState == TorchState.on;
    final zoomScale = scannerState.zoomScale.clamp(0.0, 1.0).toDouble();

    if (!_didApplyInitialZoom &&
        scannerState.isInitialized &&
        scannerState.isRunning &&
        widget.initialZoom > 0) {
      _didApplyInitialZoom = true;
      unawaited(_setZoom(widget.initialZoom));
    }

    if (!mounted ||
        (_isTorchOn == isTorchOn && (_zoomScale - zoomScale).abs() < 0.01)) {
      return;
    }

    setState(() {
      _isTorchOn = isTorchOn;
      _zoomScale = zoomScale;
    });
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
      await TerminalFeedback.success();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(rawValue);
      return;
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
  }

  Future<void> _setZoom(double value) async {
    try {
      await _controller.setZoomScale(value.clamp(0.0, 1.0).toDouble());
    } catch (_) {
      // Some devices reject zoom changes while the camera is still starting.
    }
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

  Rect _scanWindowFor(Size size) {
    final maxByWidth = math.max(160.0, size.width - 40);
    final maxByHeight = math.max(160.0, size.height * 0.52);
    final preferred = widget.qrOnly ? 320.0 : 280.0;
    final boxSize = math.min(preferred, math.min(maxByWidth, maxByHeight));
    final halfBox = boxSize / 2;
    final bottomLimit = math.max(halfBox + 24, size.height - 150);
    final centerY = math.max(
      halfBox + 20,
      math.min(size.height * 0.40, bottomLimit - halfBox),
    );

    return Rect.fromCenter(
      center: Offset(size.width / 2, centerY),
      width: boxSize,
      height: boxSize,
    );
  }

  Widget _buildScannerFrame(Rect scanWindow) {
    return Positioned.fromRect(
      rect: scanWindow,
      child: IgnorePointer(
        child: Container(
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
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    final showZoom = widget.showZoomControl && !kIsWeb;

    return Align(
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
              if (showZoom) ...<Widget>[
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    Expanded(
                      child: Slider(
                        value: _zoomScale.clamp(0.0, 1.0).toDouble(),
                        min: 0,
                        max: 1,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _zoomScale = value;
                          });
                          unawaited(_setZoom(value));
                        },
                      ),
                    ),
                    Text(
                      '${(_zoomScale * 100).round()}%',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text(
                widget.qrOnly
                    ? 'QR kucukse yakinlastirin; parlama varsa feneri kapatin.'
                    : 'Okuma olmuyorsa ortami aydinlatin ve barkodu kutu icinde tutun.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
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
          LayoutBuilder(
            builder: (context, constraints) {
              final scanWindow = _scanWindowFor(constraints.biggest);

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  MobileScanner(
                    controller: _controller,
                    scanWindow: scanWindow,
                    scanWindowUpdateThreshold: 12,
                    onDetect: _handleDetection,
                  ),
                  _buildScannerFrame(scanWindow),
                ],
              );
            },
          ),
          _buildBottomPanel(context),
        ],
      ),
    );
  }
}
