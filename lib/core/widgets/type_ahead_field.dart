import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:gigways/core/theme/themes.dart';

class AppTypeAheadField<T> extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final List<T> items;
  final String Function(T) itemToString;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(T) onSelected;
  final void Function(bool)? onFocusChanged;
  final bool showOnFocus;
  final bool hideKeyboardOnDrag;
  final bool hideOnEmpty;
  final bool hideWithKeyboard;

  const AppTypeAheadField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.items,
    required this.itemToString,
    required this.itemBuilder,
    required this.onSelected,
    this.onFocusChanged,
    this.showOnFocus = true,
    this.hideKeyboardOnDrag = true,
    this.hideOnEmpty = true,
    this.hideWithKeyboard = true,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<T>(
      controller: controller,
      builder: (context, controller, focusNode) {
        return Focus(
          onFocusChange: onFocusChanged,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: AppTextStyle.size(16).regular.withColor(AppColorToken.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColorToken.black.value.withAlpha(50),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText: hintText,
              hintStyle: AppTextStyle.size(16).regular.withColor(
                    AppColorToken.white..color.withAlpha(50),
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColorToken.white.value.withAlpha(30),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColorToken.white.value.withAlpha(30),
                ),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            onTap: () {
              focusNode.requestFocus();
            },
          ),
        );
      },
      showOnFocus: showOnFocus,
      hideKeyboardOnDrag: hideKeyboardOnDrag,
      hideOnEmpty: hideOnEmpty,
      suggestionsCallback: (pattern) async {
        return items.where((item) {
          final itemString = itemToString(item).toLowerCase();
          return itemString.contains(pattern.toLowerCase());
        }).toList();
      },
      itemBuilder: itemBuilder,
      onSelected: (T value) {
        controller.text = itemToString(value);
        FocusScope.of(context).unfocus();
        onSelected(value);
      },
      hideWithKeyboard: hideWithKeyboard,
    );
  }
}
