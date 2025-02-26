import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';

class CreatePostBottomSheet extends StatefulWidget {
  final Function(String) onPostCreated;

  const CreatePostBottomSheet({
    super.key,
    required this.onPostCreated,
  });

  @override
  State<CreatePostBottomSheet> createState() => _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends State<CreatePostBottomSheet> {
  final _textController = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorToken.white.value.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            16.verticalSpace,

            // Header
            Text(
              'Create Post',
              style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
            ),
            16.verticalSpace,

            // Text field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColorToken.black.value.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorToken.white.value.withAlpha(30),
                ),
              ),
              child: TextField(
                controller: _textController,
                style: AppTextStyle.size(16)
                    .regular
                    .withColor(AppColorToken.white),
                maxLines: 5,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'What\'s on your mind?',
                  hintStyle: AppTextStyle.size(16)
                      .regular
                      .withColor(AppColorToken.white..color.withAlpha(50)),
                ),
                onChanged: (value) {
                  setState(() {
                    _isComposing = value.trim().isNotEmpty;
                  });
                },
              ),
            ),
            24.verticalSpace,

            // Post button
            AppButton(
              text: 'Post',
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  widget.onPostCreated(text);
                  Navigator.pop(context);
                }
              },
              disabled: !_isComposing,
            ),
            16.verticalSpace,
          ],
        ),
      ),
    );
  }
}
