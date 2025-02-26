import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    Key? key,
    required this.router,
  }) : super(key: key);

  static const String path = '/dashboard';

  final StatefulNavigationShell router;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.access_time_filled_outlined),
            label: 'Strike',
          ),
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
        selectedIndex: router.currentIndex,
        animationDuration: Duration(milliseconds: 300),
        elevation: 6,
        onDestinationSelected: router.goBranch,
        indicatorColor: AppColorToken.golden.value,
        height: 62,
      ),
      body: router,
    );
  }
}
