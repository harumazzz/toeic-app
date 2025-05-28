import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.name,
    required this.labelText,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.keyboardType,
    required this.validator,
    this.obscureText = false,
    this.onSubmitted,
    super.key,
  });

  final String name;
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final String? Function(String? value)? validator;
  final bool obscureText;
  final void Function(String? value)? onSubmitted;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: FormBuilderTextField(
      name: name,
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
    ),
  );

  static AuthTextField email({
    required final TextEditingController controller,
    required final FocusNode focusNode,
    required final String labelText,
    required final String hintText,
    final void Function(String?)? onSubmitted,
  }) => AuthTextField(
    name: 'email',
    labelText: labelText,
    hintText: hintText,
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.emailAddress,
    validator: FormBuilderValidators.compose([
      FormBuilderValidators.required(),
      FormBuilderValidators.email(),
    ]),
    onSubmitted: onSubmitted,
  );

  static AuthTextField password({
    required final TextEditingController controller,
    required final FocusNode focusNode,
    required final String labelText,
    required final String hintText,
    final void Function(String?)? onSubmitted,
  }) => AuthTextField(
    name: 'password',
    labelText: labelText,
    hintText: hintText,
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.visiblePassword,
    obscureText: true,
    validator: FormBuilderValidators.required(),
    onSubmitted: onSubmitted,
  );

  static AuthTextField username({
    required final TextEditingController controller,
    required final FocusNode focusNode,
    required final String labelText,
    required final String hintText,
    final void Function(String?)? onSubmitted,
  }) => AuthTextField(
    name: 'username',
    labelText: labelText,
    hintText: hintText,
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.name,
    validator: FormBuilderValidators.compose([
      FormBuilderValidators.required(),
      FormBuilderValidators.username(),
    ]),
    onSubmitted: onSubmitted,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('hintText', hintText))
      ..add(
        DiagnosticsProperty<TextEditingController>('controller', controller),
      )
      ..add(DiagnosticsProperty<FocusNode>('focusNode', focusNode))
      ..add(DiagnosticsProperty<TextInputType>('keyboardType', keyboardType))
      ..add(
        ObjectFlagProperty<String? Function(String? value)?>.has(
          'validator',
          validator,
        ),
      )
      ..add(DiagnosticsProperty<bool>('obscureText', obscureText))
      ..add(
        ObjectFlagProperty<void Function(String? value)?>.has(
          'onSubmitted',
          onSubmitted,
        ),
      );
  }
}
