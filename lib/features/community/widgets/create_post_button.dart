import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';

class CreatePostButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CreatePostButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColorToken.golden.value,
      child: Icon(
        Icons.edit_outlined,
        color: AppColorToken.black.value,
      ),
    );
  }
}