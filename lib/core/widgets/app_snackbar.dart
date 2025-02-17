import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SnackbarType { error, success, loading }

class SnackbarData {
  final String message;
  final SnackbarType type;
  final Duration duration;

  const SnackbarData({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
  });
}

// Provider to manage snackbar state
final snackbarProvider =
    StateNotifierProvider<SnackbarController, SnackbarData?>((ref) {
  return SnackbarController();
});

class SnackbarController extends StateNotifier<SnackbarData?> {
  SnackbarController() : super(null);

  void showSnackbar(SnackbarData data) {
    state = data;
    if (data.type != SnackbarType.loading) {
      Future.delayed(data.duration, () {
        if (mounted) {
          state = null;
        }
      });
    }
  }

  void hideSnackbar() {
    state = null;
  }
}

class AppSnackbar extends ConsumerWidget {
  final Widget child;

  const AppSnackbar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snackbarData = ref.watch(snackbarProvider);

    return Material(
      child: Stack(
        children: [
          child,
          if (snackbarData != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: -1.0, end: 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Positioned(
                  top: MediaQuery.of(context).padding.top + (value * 100),
                  left: 16,
                  right: 16,
                  child: child!,
                );
              },
              child: _SnackbarContent(data: snackbarData),
            ),
        ],
      ),
    );
  }
}

class _SnackbarContent extends ConsumerWidget {
  final SnackbarData data;

  const _SnackbarContent({
    required this.data,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              if (data.type != SnackbarType.loading)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    ref.read(snackbarProvider.notifier).hideSnackbar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (data.type) {
      case SnackbarType.error:
        return const Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 24,
        );
      case SnackbarType.success:
        return const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 24,
        );
      case SnackbarType.loading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (data.type) {
      case SnackbarType.error:
        return Theme.of(context).colorScheme.error;
      case SnackbarType.success:
        return Colors.green;
      case SnackbarType.loading:
        return Colors.blue;
    }
  }
}
