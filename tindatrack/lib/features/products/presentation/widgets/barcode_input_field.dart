import 'package:flutter/material.dart';

/// Text input for optional product barcodes with an adjacent scan action.
final class BarcodeInputField extends StatelessWidget {
  /// Creates a barcode input field.
  const BarcodeInputField({
    required this.fieldKey,
    required this.scanButtonKey,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.enabled,
    required this.onScan,
    bool? scanEnabled,
    this.error,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  }) : scanEnabled = scanEnabled ?? enabled;

  /// Key applied to the underlying text field.
  final Key fieldKey;

  /// Key applied to the scan icon button.
  final Key scanButtonKey;

  /// Text controller for manual and scanned barcode values.
  final TextEditingController controller;

  /// Focus node for the text field.
  final FocusNode focusNode;

  /// Field label.
  final String label;

  /// Whether the text field and scan action are enabled.
  final bool enabled;

  /// Whether the scan action is enabled.
  final bool scanEnabled;

  /// Inline validation error.
  final String? error;

  /// Keyboard action for manual entry.
  final TextInputAction? textInputAction;

  /// Manual-entry submit callback.
  final ValueChanged<String>? onSubmitted;

  /// Called when the user starts barcode scanning.
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        suffixIcon: IconButton(
          key: scanButtonKey,
          tooltip: 'Scan barcode',
          onPressed: scanEnabled ? onScan : null,
          icon: const Icon(Icons.qr_code_scanner),
        ),
      ),
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
    );
  }
}
