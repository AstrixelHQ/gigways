import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/features/onboarding/pages/pages.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return _router;
});

final GoRouter _router = GoRouter(
  routes: $appRoutes,
  debugLogDiagnostics: true,
);

@TypedGoRoute<SplashRoute>(path: SplashPage.path)
class SplashRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashPage();
  }
}
