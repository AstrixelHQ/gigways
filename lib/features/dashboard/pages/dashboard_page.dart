import 'package:flutter/material.dart';
import 'package:gigways/core/services/activity_service.dart';
import 'package:gigways/core/services/permission_service.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    Key? key,
    required this.router,
  }) : super(key: key);

  static const String path = '/dashboard';

  final StatefulNavigationShell router;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Request permissions after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAppPermissions();
    });
  }

  Future<void> _requestAppPermissions() async {
    // Request permissions sequentially with proper explanation sheets
    final permissionService = PermissionService();

    // Check which permissions are already granted
    final permissionStatus = await permissionService.getPermissionStatus();

    // If not all permissions are granted, show the flow
    if (permissionStatus.values.contains(false)) {
      await permissionService.requestPermissions(context);
    }

    if (permissionStatus[AppPermission.activityRecognition] == true ||
        permissionStatus[AppPermission.location] == true) {
      ActivityService().start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.access_time_filled_outlined),
            label: 'Voices',
          ),
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.people_outline),
          //   label: 'Community',
          // ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
        selectedIndex: widget.router.currentIndex,
        animationDuration: Duration(milliseconds: 300),
        elevation: 6,
        onDestinationSelected: widget.router.goBranch,
        indicatorColor: AppColorToken.golden.value,
        height: 62,
      ),
      body: widget.router,
    );
  }
}
