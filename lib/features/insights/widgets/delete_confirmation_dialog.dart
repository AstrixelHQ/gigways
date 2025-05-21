import 'package:flutter/material.dart';
import 'package:gigways/core/theme/app_colors.dart';
import 'package:gigways/core/theme/app_text_styles.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog(
      {Key? key, required this.title, required this.description, this.onDelete})
      : super(key: key);

  final String title;
  final String description;
  final VoidCallback? onDelete;

  static Future<void> show(
      BuildContext context, String title, String description,
      {VoidCallback? onDelete}) async {
    await showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: title,
        description: description,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColorToken.black.value,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorToken.golden.value.withAlpha(50)),
      ),
      title: Text(
        title,
        style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
      ),
      content: Text(
        description,
        style: AppTextStyle.size(14).regular.withColor(AppColorToken.white),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTextStyle.size(14).medium.withColor(AppColorToken.white),
          ),
        ),
        TextButton(
          onPressed: () {
            if (onDelete != null) {
              onDelete!();
            }
          },
          child: Text(
            'Delete',
            style: AppTextStyle.size(14).medium.withColor(AppColorToken.red),
          ),
        ),
      ],
    );
  }
}
