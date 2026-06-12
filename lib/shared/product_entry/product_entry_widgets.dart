import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class ProductLookupField extends StatelessWidget {
  const ProductLookupField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.enabled = true,
    this.labelText = 'Barkod / stok kodu / urun adi',
    this.hintText,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSubmit;
  final bool enabled;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TerminalSubmitOnTab(
      enabled: enabled,
      onSubmit: onSubmit,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}
