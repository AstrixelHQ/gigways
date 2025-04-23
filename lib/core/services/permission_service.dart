import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/services/motion_permission.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission {
  location,
  activityRecognition,
  notification,
}

class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Track which explanations have been shown to avoid repetition
  final Map<AppPermission, bool> _hasShownExplanation = {};

  // Request all required permissions in sequence
  Future<bool> requestPermissions(BuildContext context,
      {AppPermission? specificPermission}) async {
    final permissionsToRequest = [
      AppPermission.location,
      AppPermission.activityRecognition,
      AppPermission.notification,
    ];

    // Check which permissions are already granted
    final permissionStatus = await getPermissionStatus();
    final permissionsNeeded = permissionsToRequest
        .where(
          (permission) => !(permissionStatus[permission] ?? false),
        )
        .toList();

    if (permissionsNeeded.isEmpty) {
      return true;
    }

    // If specific permission is requested, ensure it's in the list
    if (specificPermission != null &&
        !permissionsNeeded.contains(specificPermission)) {
      permissionsNeeded.add(specificPermission);
    }

    // Show the PageView bottom sheet
    final result = await showModalBottomSheet<bool>(
          context: context,
          isDismissible: true,
          enableDrag: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PermissionPageView(
            permissions: permissionsNeeded,
            onComplete: (allGranted) async {
              if (allGranted) {
                // Request actual permissions
                for (final permission in permissionsNeeded) {
                  final granted = await _requestPermission(permission);
                  if (!granted) {
                    await _showSettingsDialog(context, permission);
                    return false;
                  }
                }
                return true;
              }
              return false;
            },
          ),
        ) ??
        false;

    return result;
  }

  // Get current status of all permissions
  Future<Map<AppPermission, bool>> getPermissionStatus() async {
    final status = <AppPermission, bool>{};
    for (final permission in AppPermission.values) {
      status[permission] = await _isPermissionGranted(permission);
    }
    return status;
  }

  // Check if a specific permission is granted
  Future<bool> _isPermissionGranted(AppPermission permission) async {
    switch (permission) {
      case AppPermission.location:
        // return await Permission.location.isGranted;
        final status = await Permission.location.status;
        if (status.isGranted) {
          return true;
        } else if (status.isDenied) {
          return false;
        } else if (status.isPermanentlyDenied) {
          return false;
        }
        return false;
      case AppPermission.activityRecognition:
        final status = await MotionPermission.checkStatus();

        return status;
      case AppPermission.notification:
        final status = await Permission.notification.status;
        if (status.isGranted) {
          return true;
        } else if (status.isDenied) {
          // Request permission if denied
          final requestStatus = await Permission.notification.request();
          return requestStatus.isGranted;
        } else if (status.isPermanentlyDenied) {
          return false;
        }
        return false;
    }
  }

  // Request a specific permission
  Future<bool> _requestPermission(AppPermission permission) async {
    switch (permission) {
      case AppPermission.location:
        final status = await Permission.location.request();
        return status.isGranted;
      case AppPermission.activityRecognition:
        final status = await MotionPermission.request();
        return status;
      case AppPermission.notification:
        final status = await Permission.notification.request();
        return status.isGranted;
    }
  }

  // Show settings dialog when permission is denied
  Future<void> _showSettingsDialog(
      BuildContext context, AppPermission permission) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorToken.black.value,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColorToken.golden.value.withAlpha(30)),
        ),
        title: Text(
          'Permission Required',
          style: AppTextStyle.size(20).bold.withColor(AppColorToken.golden),
        ),
        content: Text(
          '${_getPermissionName(permission)} permission is required for the app to function properly. Please enable it in your device settings.',
          style: AppTextStyle.size(16).regular.withColor(AppColorToken.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not Now',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.golden),
            ),
          ),
        ],
      ),
    );
  }

  String _getPermissionName(AppPermission permission) {
    switch (permission) {
      case AppPermission.location:
        return 'Location';
      case AppPermission.activityRecognition:
        return 'Activity Recognition';
      case AppPermission.notification:
        return 'Notification';
    }
  }
}

class PermissionPageView extends StatefulWidget {
  final List<AppPermission> permissions;
  final Function(bool) onComplete;

  const PermissionPageView({
    super.key,
    required this.permissions,
    required this.onComplete,
  });

  @override
  State<PermissionPageView> createState() => _PermissionPageViewState();
}

class _PermissionPageViewState extends State<PermissionPageView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<AppPermission, bool> _permissionResponses = {};
  final Map<AppPermission, PermissionStatus> _permissionStatuses = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializePermissionStatuses();
  }

  Future<void> _initializePermissionStatuses() async {
    final permissionService = PermissionService();
    for (final permission in widget.permissions) {
      final status = await _getPermissionStatus(permission);
      setState(() {
        _permissionStatuses[permission] = status;
        _permissionResponses[permission] = status.isGranted;
      });
    }
  }

  Future<PermissionStatus> _getPermissionStatus(
      AppPermission permission) async {
    switch (permission) {
      case AppPermission.location:
        return await Permission.location.status;
      case AppPermission.activityRecognition:
        final status = await MotionPermission.checkStatus();
        return status ? PermissionStatus.granted : PermissionStatus.denied;
      case AppPermission.notification:
        return await Permission.notification.status;
    }
  }

  void _handlePermissionResponse(AppPermission permission, bool granted) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (!granted) {
        // If user declined, update status and move to next permission
        setState(() {
          _permissionResponses[permission] = false;
        });

        if (_currentPage < widget.permissions.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Check if all permissions are granted
          final allGranted =
              _permissionResponses.values.every((granted) => granted);
          if (allGranted) {
            Navigator.pop(context, true);
          } else {
            // Navigate back to first ungranted permission
            final firstUngrantedIndex = widget.permissions.indexWhere(
              (p) => !(_permissionResponses[p] ?? false),
            );
            if (firstUngrantedIndex != -1) {
              _pageController.animateToPage(
                firstUngrantedIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        }
        return;
      }

      // If user allowed, request actual permission
      final permissionService = PermissionService();
      final status = await permissionService._requestPermission(permission);

      setState(() {
        _permissionStatuses[permission] =
            status ? PermissionStatus.granted : PermissionStatus.denied;
        _permissionResponses[permission] = status;
      });

      if (!status) {
        // If permission was denied, show settings dialog
        await permissionService._showSettingsDialog(context, permission);
      }

      // Check if all permissions are granted
      final allGranted =
          _permissionResponses.values.every((granted) => granted);
      if (allGranted) {
        Navigator.pop(context, true);
        return;
      }

      // Move to next ungranted permission
      if (_currentPage < widget.permissions.length - 1) {
        final nextUngrantedIndex = widget.permissions.indexWhere(
          (p) => !(_permissionResponses[p] ?? false),
          _currentPage + 1,
        );

        if (nextUngrantedIndex != -1) {
          _pageController.animateToPage(
            nextUngrantedIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // If no more ungranted permissions after current, go back to first ungranted
          final firstUngrantedIndex = widget.permissions.indexWhere(
            (p) => !(_permissionResponses[p] ?? false),
          );
          if (firstUngrantedIndex != -1) {
            _pageController.animateToPage(
              firstUngrantedIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      } else {
        // If we're at the last permission, go back to first ungranted
        final firstUngrantedIndex = widget.permissions.indexWhere(
          (p) => !(_permissionResponses[p] ?? false),
        );
        if (firstUngrantedIndex != -1) {
          _pageController.animateToPage(
            firstUngrantedIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PageView
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: widget.permissions.map((permission) {
                return PermissionExplanationSheet(
                  permission: permission,
                  onResponse: (granted) =>
                      _handlePermissionResponse(permission, granted),
                  status: _permissionStatuses[permission] ??
                      PermissionStatus.denied,
                );
              }).toList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.permissions.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? AppColorToken.golden.value
                        : AppColorToken.white.value.withAlpha(50),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionExplanationSheet extends StatelessWidget {
  final AppPermission permission;
  final Function(bool) onResponse;
  final PermissionStatus status;

  const PermissionExplanationSheet({
    super.key,
    required this.permission,
    required this.onResponse,
    required this.status,
  });

  String _getButtonText() {
    if (status == PermissionStatus.granted) {
      return 'Granted';
    } else if (status == PermissionStatus.permanentlyDenied) {
      return 'Open Settings';
    }
    return 'Allow';
  }

  bool _isButtonEnabled() {
    return status != PermissionStatus.granted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getPermissionTitle(),
            style: AppTextStyle.size(24).bold.withColor(AppColorToken.golden),
          ),
          16.verticalSpace,

          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColorToken.golden.value.withAlpha(20),
              ),
              child: Icon(
                _getPermissionIcon(),
                color: AppColorToken.golden.value,
                size: 50,
              ),
            ),
          ),
          24.verticalSpace,

          // Description
          Text(
            _getPermissionDescription(),
            style: AppTextStyle.size(16).regular.withColor(AppColorToken.white),
          ),
          32.verticalSpace,

          // Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Not Now',
                  onPressed: () => onResponse(false),
                  backgroundColor: AppColorToken.black.value,
                  textColor: AppColorToken.white.value,
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: AppButton(
                  text: _getButtonText(),
                  onPressed:
                      _isButtonEnabled() ? () => onResponse(true) : () {},
                  backgroundColor: AppColorToken.golden.value,
                  disabled: !_isButtonEnabled(),
                ),
              ),
            ],
          ),
          16.verticalSpace,
        ],
      ),
    );
  }

  IconData _getPermissionIcon() {
    switch (permission) {
      case AppPermission.location:
        return Icons.location_on;
      case AppPermission.activityRecognition:
        return Icons.directions_car;
      case AppPermission.notification:
        return Icons.notifications;
    }
  }

  String _getPermissionTitle() {
    switch (permission) {
      case AppPermission.location:
        return 'Location Access';
      case AppPermission.activityRecognition:
        return 'Driving Detection';
      case AppPermission.notification:
        return 'Notifications';
    }
  }

  String _getPermissionDescription() {
    switch (permission) {
      case AppPermission.location:
        return 'GigWays needs your location to track miles driven and help you coordinate with other drivers in your area. We only use your location while you are actively using the app or tracking your driving sessions.';
      case AppPermission.activityRecognition:
        return 'This permission allows GigWays to detect when you are driving. It helps automatically track your driving sessions without manual intervention, making time tracking more accurate and convenient.';
      case AppPermission.notification:
        return 'Stay informed about upcoming coordinated breaks, changes to schedules, and important app updates. Notifications help you connect with other drivers and make the most of your work schedule.';
    }
  }
}
