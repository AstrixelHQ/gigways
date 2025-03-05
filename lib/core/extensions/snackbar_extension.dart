import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/widgets/app_snackbar.dart';

extension SnackbarExtension on BuildContext {
  void showErrorSnackbar(String message) {
    // read(snackbarProvider.notifier).showSnackbar(
    //   SnackbarData(
    //     message: message,
    //     type: SnackbarType.error,
    //   ),
    // );
  }

  void showSuccessSnackbar(String message) {}

  void showLoadingSnackbar(String message) {
    // read(snackbarProvider.notifier).showSnackbar(
    //   SnackbarData(
    //     message: message,
    //     type: SnackbarType.loading,
    //     duration: const Duration(days: 1), // Long duration for loading state
    //   ),
    // );
  }

  void hideSnackbar() {
    // read(snackbarProvider.notifier).hideSnackbar();
  }
}
