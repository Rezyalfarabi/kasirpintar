import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kasir_pintar/shared_widgets/inputs/input_field.dart';
import 'package:kasir_pintar/core/utils/validators.dart';

class NumericInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final String? errorText;
  final bool allowDecimal;
  final int? maxValue;

  const NumericInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.textInputAction,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.errorText,
    this.allowDecimal = false,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    String? Function(String?) effectiveValidator;
    if (validator != null) {
      effectiveValidator = validator!;
    } else if (allowDecimal) {
      effectiveValidator = (value) => Validators.nonNegativeInteger(value, fieldName: label);
    } else {
      effectiveValidator = (value) => Validators.positiveInteger(value, fieldName: label);
    }

    return InputField(
      label: label,
      hint: hint,
      controller: controller,
      validator: (value) {
        final validationError = effectiveValidator(value);
        if (validationError != null) return validationError;
        if (maxValue != null) {
          final parsed = allowDecimal
              ? double.tryParse(value?.replaceAll(',', '.') ?? '')
              : int.tryParse(value?.replaceAll(',', '') ?? '');
          if (parsed != null && parsed > maxValue!) {
            return '$label maksimal $maxValue';
          }
        }
        return null;
      },
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true, signed: false)
          : TextInputType.number,
      textInputAction: textInputAction,
      enabled: enabled,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      errorText: errorText,
      inputFormatters: allowDecimal
          ? [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))]
          : [FilteringTextInputFormatter.digitsOnly],
    );
  }
}