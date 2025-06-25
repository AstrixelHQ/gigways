import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/services/permission_service.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/scaffold_wrapper.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsPage extends ConsumerStatefulWidget {
  const PermissionsPage({super.key});

  static const String path = '/permissions';

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage> {
  late PermissionService _permissionService;
  Map<AppPermission, bool> _permissionStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _permissionService = PermissionService();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    try {
      final status = await _permissionService.getPermissionStatus();
      setState(() {
        _permissionStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePermissionToggle(AppPermission permission) async {
    final isCurrentlyGranted = _permissionStatus[permission] ?? false;

    if (isCurrentlyGranted) {
      // If permission is granted, redirect to system settings to disable
      await openAppSettings();
    } else {
      // If permission is not granted, request it
      await _permissionService.requestPermissions(context);
      // Refresh status after request
      await _loadPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      shouldShowGradient: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,
            // Header
            SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColorToken.golden.value,
                      size: 24,
                    ),
                  ),
                  Text(
                    'Permissions',
                    style: AppTextStyle.size(24)
                        .bold
                        .withColor(AppColorToken.golden),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColorToken.golden.value,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          32.verticalSpace,

                          // Description
                          Text(
                            'Manage app permissions to customize your GigWays experience',
                            style: AppTextStyle.size(16).regular.withColor(
                                  AppColorToken.white..value.withOpacity(0.8),
                                ),
                          ),

                          32.verticalSpace,

                          // Permission Cards
                          ..._buildPermissionCards(),

                          32.verticalSpace,

                          // Info Card
                          _buildInfoCard(),

                          32.verticalSpace,
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPermissionCards() {
    final permissions = [
      {
        'permission': AppPermission.location,
        'title': 'Location Access',
        'description':
            'Required for tracking miles and coordinating with nearby drivers',
        'icon': Icons.location_on_outlined,
        'critical': true,
      },
      {
        'permission': AppPermission.activityRecognition,
        'title': 'Activity Recognition',
        'description': 'Automatically detects when you start or stop driving',
        'icon': Icons.directions_car_outlined,
        'critical': true,
      },
      {
        'permission': AppPermission.notification,
        'title': 'Notifications',
        'description': 'Stay updated with coordinated breaks and app updates',
        'icon': Icons.notifications_outlined,
        'critical': false,
      },
    ];

    return permissions.map((perm) {
      final permission = perm['permission'] as AppPermission;
      final isGranted = _permissionStatus[permission] ?? false;
      final isCritical = perm['critical'] as bool;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPermissionCard(
          title: perm['title'] as String,
          description: perm['description'] as String,
          icon: perm['icon'] as IconData,
          isGranted: isGranted,
          isCritical: isCritical,
          onToggle: () => _handlePermissionToggle(permission),
        ),
      );
    }).toList();
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required bool isCritical,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorToken.white.value.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColorToken.golden.value.withOpacity(0.5)
              : AppColorToken.white.value.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColorToken.golden.value.withOpacity(0.2)
                      : AppColorToken.white.value.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isGranted
                      ? AppColorToken.golden.value
                      : AppColorToken.white.value.withOpacity(0.7),
                  size: 24,
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyle.size(18)
                              .semiBold
                              .withColor(AppColorToken.white),
                        ),
                        if (isCritical) ...[
                          8.horizontalSpace,
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Required',
                              style: AppTextStyle.size(10)
                                  .medium
                                  .withColor(AppColorToken.golden),
                            ),
                          ),
                        ],
                      ],
                    ),
                    4.verticalSpace,
                    Text(
                      description,
                      style: AppTextStyle.size(14).regular.withColor(
                            AppColorToken.white..color.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          20.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isGranted
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isGranted ? 'Granted' : 'Not Granted',
                  style: AppTextStyle.size(12).medium.withColor(
                      isGranted ? AppColorToken.green : AppColorToken.red),
                ),
              ),
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  backgroundColor: isGranted
                      ? AppColorToken.white.value.withOpacity(0.1)
                      : AppColorToken.golden.value,
                  foregroundColor: isGranted
                      ? AppColorToken.white.value
                      : AppColorToken.black.value,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isGranted ? 'Settings' : 'Grant',
                  style: AppTextStyle.size(14).medium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorToken.golden.value.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColorToken.golden.value,
                size: 24,
              ),
              12.horizontalSpace,
              Text(
                'About Permissions',
                style: AppTextStyle.size(16)
                    .semiBold
                    .withColor(AppColorToken.golden),
              ),
            ],
          ),
          16.verticalSpace,
          Text(
            '• Location and Activity Recognition are required for core functionality\n'
            '• You can manage permissions anytime through device settings\n'
            '• Denying critical permissions may limit app features\n'
            '• All data is processed securely and never shared without consent',
            style: AppTextStyle.size(14)
                .regular
                .withColor(AppColorToken.white..value.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
