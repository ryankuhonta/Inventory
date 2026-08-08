import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const _scannerFormats = <BarcodeFormat>[
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
];

/// Camera-backed barcode scanner that returns one scanned value.
final class BarcodeScannerScreen extends StatefulWidget {
  /// Creates a barcode scanner screen.
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

final class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _returnedResult = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: _scannerFormats,
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('barcode-scanner-screen'),
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _handleDetection,
        errorBuilder: (_, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _complete(false);
          });
          return const _ScannerUnavailableView();
        },
      ),
    );
  }

  void _handleDetection(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.trim().isEmpty) continue;
      _complete(value);
      return;
    }
  }

  void _complete(Object? result) {
    if (_returnedResult || !mounted) return;
    _returnedResult = true;
    unawaited(_controller.stop());
    Navigator.of(context).pop(result);
  }
}

final class _ScannerUnavailableView extends StatelessWidget {
  const _ScannerUnavailableView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Barcode scanning is unavailable.'),
      ),
    );
  }
}
