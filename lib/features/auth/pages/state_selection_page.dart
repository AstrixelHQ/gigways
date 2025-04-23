import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/constants/state_constant.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/core/widgets/type_ahead_field.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/routers/app_router.dart';

class StateSelectionPage extends ConsumerStatefulWidget {
  const StateSelectionPage({super.key});

  static const String path = '/state-selection';

  @override
  ConsumerState<StateSelectionPage> createState() => _StateSelectionPageState();
}

class _StateSelectionPageState extends ConsumerState<StateSelectionPage> {
  String? selectedState;
  bool isLoading = false;
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

              AppTypeAheadField<String>(
                controller: _typeAheadController,
                hintText: 'Search your state',
                items: StateConstant.usStates,
                itemToString: (state) => state,
                itemBuilder: (context, state) => ListTile(
                  title: Text(
                    state,
                    style: AppTextStyle.size(16)
                        .regular
                        .withColor(AppColorToken.white),
                  ),
                ),
                onSelected: (value) {
                  setState(() => selectedState = value);
                },
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
