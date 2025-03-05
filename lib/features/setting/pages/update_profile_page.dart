import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gigways/core/constants/state_constant.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/extensions/snackbar_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/app_text_field.dart';
import 'package:gigways/core/widgets/gradient_avatar.dart';
import 'package:gigways/core/widgets/loading_overlay.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/auth/notifiers/profile_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class UpdateProfilePage extends HookConsumerWidget {
  const UpdateProfilePage({super.key});

  static const String path = '/update-profile';
  final duration = const Duration(seconds: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user data
    final userData = ref.watch(authNotifierProvider).userData;
    final profileState = ref.watch(profileNotifierProvider);

    // Form key for validation
    final formKey = useRef(GlobalKey<FormState>()).value;

    // Create controllers for form fields
    final nameController =
        useTextEditingController(text: userData?.fullName ?? '');
    final emailController =
        useTextEditingController(text: userData?.email ?? '');
    final phoneController =
        useTextEditingController(text: userData?.phoneNumber ?? '');

    // Phone number formatter
    final phoneFormatter = MaskTextInputFormatter(
      mask: '(###) ###-####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    // State dropdown
    final selectedState = useState<String?>(userData?.state);

    // Profile image
    final profileImage = useState<File?>(null);

    ref.listen(profileNotifierProvider, (previous, next) {
      if (next.status == ProfileUpdateStatus.success) {
        context.showSuccessSnackbar('Profile updated successfully');
        Future.delayed(duration).then((_) {
          ref.read(profileNotifierProvider.notifier).resetStatus();
        });
      } else if (next.status == ProfileUpdateStatus.error) {
        context
            .showErrorSnackbar(next.errorMessage ?? 'Failed to update profile');
        Future.delayed(duration).then((_) {
          ref.read(profileNotifierProvider.notifier).resetStatus();
        });
      }
    });

    // Function to pick image
    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedImage != null) {
        profileImage.value = File(pickedImage.path);

        // Upload image
        await ref.read(profileNotifierProvider.notifier).uploadProfileImage(
              profileImage.value!,
            );
      }
    }

    // Function to handle form submission
    Future<void> handleSubmit() async {
      if (formKey.currentState?.validate() ?? false) {
        ref.read(profileNotifierProvider.notifier).updateProfile(
              fullName: nameController.text,
              email: emailController.text,
              phoneNumber:
                  phoneController.text.isEmpty ? null : phoneController.text,
              countryState: selectedState.value,
            );
      }
    }

    return LoadingOverlay(
      isLoading: profileState.status == ProfileUpdateStatus.loading,
      child: ScaffoldWrapper(
        shouldShowGradient: true,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    16.verticalSpace,
                    // Header with Back Button
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColorToken.golden.value,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColorToken.golden.value,
                              size: 20,
                            ),
                          ),
                        ),
                        16.horizontalSpace,
                        Text(
                          'Update Profile',
                          style: AppTextStyle.size(24)
                              .bold
                              .withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                    32.verticalSpace,

                    // Profile Picture Section
                    Center(
                      child: GradientAvatar(
                        name: userData?.fullName ?? 'User',
                        imageUrl: userData?.profileImageUrl,
                        size: 120,
                        isEditable: true,
                        onEdit: pickImage,
                      ),
                    ),
                    40.verticalSpace,

                    // Personal Information Section
                    Text(
                      'Personal Information',
                      style: AppTextStyle.size(18)
                          .bold
                          .withColor(AppColorToken.golden),
                    ),
                    24.verticalSpace,

                    AppTextField(
                      label: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      controller: nameController,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    16.verticalSpace,

                    AppTextField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: emailController,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Email is required';
                        }
                        if (!value!.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    16.verticalSpace,

                    AppTextField(
                      label: 'Phone Number',
                      hintText: '(555) 123-4567',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      controller: phoneController,
                      inputFormatters: [phoneFormatter],
                      validator: (value) {
                        if (value?.isNotEmpty ?? false) {
                          // Check if the phone number is complete
                          if (value!.length < 14) {
                            // (XXX) XXX-XXXX = 14 characters
                            return 'Enter a complete phone number';
                          }
                        }
                        return null;
                      },
                    ),
                    24.verticalSpace,

                    // Location Information
                    Text(
                      'Location',
                      style: AppTextStyle.size(18)
                          .bold
                          .withColor(AppColorToken.golden),
                    ),
                    24.verticalSpace,

                    // State Selection
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
                              value: selectedState.value,
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
                                selectedState.value = value;
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
                    40.verticalSpace,

                    // Update Button
                    AppButton(
                      text: 'Update Profile',
                      onPressed: handleSubmit,
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
