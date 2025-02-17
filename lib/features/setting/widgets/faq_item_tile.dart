import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/features/setting/models/faq_model.dart';

class FaqItemTile extends StatefulWidget {
  final FaqModel faq;

  const FaqItemTile({
    required this.faq,
    Key? key,
  }) : super(key: key);

  @override
  State<FaqItemTile> createState() => _FaqItemTileState();
}

class _FaqItemTileState extends State<FaqItemTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            widget.faq.question,
            style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColorToken.golden.value,
              ),
            ),
            child: Icon(
              isExpanded ? Icons.remove : Icons.add,
              color: AppColorToken.golden.value,
              size: 16,
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              isExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Text(
                widget.faq.answer,
                style: AppTextStyle.size(14)
                    .regular
                    .withColor(AppColorToken.white..color.withAlpha(70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
