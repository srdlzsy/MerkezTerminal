import 'package:flutter/material.dart';

mixin CreateFormValidation<T extends StatefulWidget> on State<T> {
  bool _createSubmitAttempted = false;

  AutovalidateMode get createFormAutovalidateMode => _createSubmitAttempted
      ? AutovalidateMode.always
      : AutovalidateMode.disabled;

  bool validateCreateForm(GlobalKey<FormState> formKey) {
    enableCreateFormValidation();
    return formKey.currentState?.validate() ?? false;
  }

  void enableCreateFormValidation() {
    if (_createSubmitAttempted) {
      return;
    }

    setState(() {
      _createSubmitAttempted = true;
    });
  }
}
