import 'package:flutter/material.dart';

import 'package:gigways/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColorToken.golden.value),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: AppColorToken.golden.value,
          size: 20,
        ),
      ),
    );
  }
}
