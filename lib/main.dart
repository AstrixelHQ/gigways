import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/constants/app_constant.dart';
import 'package:gigways/core/services/activity_service.dart';
import 'package:gigways/core/services/notification_service.dart';
import 'package:gigways/core/services/permission_service.dart';
import 'package:gigways/core/utils/ui_utils.dart';
import 'package:gigways/firebase_options.dart';
import 'package:gigways/routers/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  await initilizer(() => const App());
}

FutureOr<void> initilizer(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final permissionService = PermissionService();
  final permissionStatus = await permissionService.getPermissionStatus();

  if (permissionStatus[AppPermission.location] == true ||
      permissionStatus[AppPermission.activityRecognition] == true) {
    await ActivityService().start();
  }

  if (permissionStatus[AppPermission.notification] == true) {
    await NotificationService().initialize();
  }

  runApp(
    ProviderScope(
      child: await builder(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _router = ref.read(appRouterProvider);

    return MaterialApp.router(
      title: AppConstant.appName,
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.inter().fontFamily,
        brightness: Brightness.dark,
      ),
      builder: (context, child) {
        UIUtils.init(context);
        return child!;
      },
    );
  }
}
