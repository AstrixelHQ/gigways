import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/constants/state_constant.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/routers/app_router.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';

class StateSelectionPage extends ConsumerStatefulWidget {
  const StateSelectionPage({super.key});
  static const String path = '/state-selection';

  @override
  ConsumerState<StateSelectionPage> createState() => _StateSelectionPageState();
}

class _StateSelectionPageState extends ConsumerState<StateSelectionPage> {
  String? selectedState;
  bool isLoading = false;

  // controller for the text‐field
  final TextEditingController _typeAheadController = TextEditingController();

  @override
  void dispose() {
    _typeAheadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ← Back
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppColorToken.white.value,
                ),
              ),
              24.verticalSpace,

              // Header
              Text(
                'Welcome to GigWays!',
                style:
                    AppTextStyle.size(24).bold.withColor(AppColorToken.golden),
              ),
              12.verticalSpace,
              Text(
                'Please select your state to continue:',
                style: AppTextStyle.size(16)
                    .regular
                    .withColor(AppColorToken.white),
              ),
              32.verticalSpace,

              TypeAheadField<String>(
                controller: _typeAheadController,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: AppTextStyle.size(16)
                        .regular
                        .withColor(AppColorToken.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColorToken.black.value.withAlpha(50),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      hintText: 'Search your state',
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
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () {
                      focusNode.requestFocus();
                    },
                  );
                },
                showOnFocus: true,
                hideKeyboardOnDrag: true,
                hideOnEmpty: true,
                suggestionsCallback: (pattern) async {
                  return StateConstant.usStates
                      .where((s) =>
                          s.toLowerCase().contains(pattern.toLowerCase()))
                      .toList();
                },
                itemBuilder: (context, String suggestion) {
                  return ListTile(
                    title: Text(
                      suggestion,
                      style: AppTextStyle.size(16)
                          .regular
                          .withColor(AppColorToken.white),
                    ),
                  );
                },
                onSelected: (String value) {
                  _typeAheadController.text = value;
                  FocusScope.of(context).unfocus();
                  setState(() => selectedState = value);
                },
                hideWithKeyboard: true,
              ),

              const Spacer(),

              // Continue Button
              AppButton(
                text: 'Continue',
                loading: isLoading,
                disabled: selectedState == null || isLoading,
                onPressed: () async {
                  if (selectedState != null) {
                    setState(() => isLoading = true);
                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .updateUserState(selectedState!);
                      HomeRoute().go(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => isLoading = false);
                    }
                  }
                },
              ),
              16.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
