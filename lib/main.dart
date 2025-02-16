import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/core/utils/ui_utils.dart';
import 'package:gigways/routers/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  await initilizer(() => const App());
}

FutureOr<void> initilizer(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

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
    final _router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Gigways Hero',
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
