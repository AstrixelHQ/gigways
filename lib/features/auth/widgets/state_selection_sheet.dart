import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/constants/state_constant.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';

class StateSelectionSheet extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;

  const StateSelectionSheet({
    Key? key,
    required this.onCompleted,
  }) : super(key: key);

  @override
  ConsumerState<StateSelectionSheet> createState() =>
      _StateSelectionSheetState();
}

class _StateSelectionSheetState extends ConsumerState<StateSelectionSheet> {
  String? selectedState;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
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
              24.verticalSpace,

              // Header
              Text(
                'Welcome to GigWays!',
                style:
                    AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
              ),
              12.verticalSpace,
              Text(
                'Please select your state to continue:',
                style: AppTextStyle.size(16)
                    .regular
                    .withColor(AppColorToken.white),
              ),
              20.verticalSpace,

              // State Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State',
                    style: AppTextStyle.size(14)
                        .medium
                        .withColor(AppColorToken.white),
                  ),
                  8.verticalSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: AppColorToken.black.value.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorToken.white.value.withAlpha(30),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: selectedState,
                        hint: Text(
                          'Select your state',
                          style: AppTextStyle.size(16).regular.withColor(
                              AppColorToken.white..color.withAlpha(50)),
                        ),
                        items: StateConstant.usStates.map((String state) {
                          return DropdownMenuItem<String>(
                            value: state,
                            child: Text(
                              state,
                              style: AppTextStyle.size(16)
                                  .regular
                                  .withColor(AppColorToken.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedState = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a state';
                          }
                          return null;
                        },
                        dropdownColor: AppColorToken.black.value,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: AppColorToken.golden.value,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppColorToken.golden.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              24.verticalSpace,

              // Continue Button
              AppButton(
                text: 'Continue',
                loading: isLoading,
                disabled: selectedState == null || isLoading,
                onPressed: () async {
                  if (selectedState != null) {
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .updateUserState(selectedState!);
                      widget.onCompleted();
                    } catch (e) {
                      // Show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
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
