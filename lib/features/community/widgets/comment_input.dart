import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/community/models/comment_model.dart';

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSubmit;
  final CommentModel? replyingTo;
  final VoidCallback onCancelReply;

  const CommentInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    this.replyingTo,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom / 3,
      ),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply indicator (if replying)
          if (replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Replying to ',
                    style: AppTextStyle.size(12)
                        .regular
                        .withColor(AppColorToken.white..color.withAlpha(100)),
                  ),
                  Text(
                    replyingTo!.userName,
                    style: AppTextStyle.size(12)
                        .medium
                        .withColor(AppColorToken.golden),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColorToken.white.value.withAlpha(10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColorToken.white.value.withAlpha(150),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Comment input field
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // User avatar (simplified)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColorToken.primary.value,
                  border: Border.all(
                    color: AppColorToken.golden.value,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Y',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              8.horizontalSpace,

              // Input field
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withAlpha(100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColorToken.white.value.withAlpha(30),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: AppTextStyle.size(14)
                        .regular
                        .withColor(AppColorToken.white),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: replyingTo != null
                          ? 'Write a reply...'
                          : 'Add a comment...',
                      hintStyle: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white..color.withAlpha(70)),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              8.horizontalSpace,

              // Send button
              GestureDetector(
                onTap: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    onSubmit(text);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColorToken.golden.value,
                  ),
                  child: Icon(
                    Icons.send,
                    size: 20,
                    color: AppColorToken.black.value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
