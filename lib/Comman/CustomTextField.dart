import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/material/input_decorator.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;
  const CustomTextField({
    required this.textEditingController,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.validator,
    this.focusNode,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.sentences
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: decoration,
      obscureText: obscureText,
      controller: textEditingController,
      keyboardType: keyboardType,
      validator: validator,
 focusNode: focusNode,
      autovalidateMode: this.autovalidateMode,
    );
  }
}