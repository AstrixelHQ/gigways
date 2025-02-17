import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/constants/state_constant.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/core/widgets/app_text_field.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class UpdateProfilePage extends ConsumerStatefulWidget {
  const UpdateProfilePage({super.key});

  static const String path = '/update-profile';

  @override
  ConsumerState<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends ConsumerState<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedState;

  // Phone number formatter
  final phoneFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
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
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColorToken.black.value,
                            border: Border.all(
                              color: AppColorToken.golden.value,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 60,
                            color: AppColorToken.golden.value,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              // Handle image upload
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColorToken.golden.value,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColorToken.black.value,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: AppColorToken.black.value,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    inputFormatters: [phoneFormatter],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Phone number is required';
                      }
                      // Check if the phone number is complete
                      if (value!.length < 14) {
                        // (XXX) XXX-XXXX = 14 characters
                        return 'Enter a complete phone number';
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
                  40.verticalSpace,

                  // Update Button
                  AppButton(
                    text: 'Update Profile',
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // Handle profile update
                        print('Selected State: $selectedState');
                      }
                    },
                  ),
                  24.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
