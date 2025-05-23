import 'package:flutter/material.dart';

extension SnackbarExtension on BuildContext {
  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void showSuccessSnackbar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, action: action),
    );
  }

  void showLoadingSnackbar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void hideSnackbar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }
}
