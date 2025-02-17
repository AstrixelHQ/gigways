import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/features/auth/pages/pages.dart';
import 'package:gigways/features/dashboard/pages/pages.dart';
import 'package:gigways/features/home/pages/pages.dart';
import 'package:gigways/features/onboarding/pages/pages.dart';
import 'package:gigways/features/setting/models/policy_model.dart';
import 'package:gigways/features/setting/pages/pages.dart';
import 'package:gigways/features/strike/pages/pages.dart';
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

@TypedGoRoute<OnboardingRoute>(path: OnboardingPage.path)
class OnboardingRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OnboardingPage();
  }
}

@TypedGoRoute<SignupRoute>(path: SignupPage.path)
class SignupRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SignupPage();
  }
}

@TypedGoRoute<LoginRoute>(path: LoginPage.path)
class LoginRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginPage();
  }
}

@TypedGoRoute<ForgotPasswordRoute>(path: ForgotPasswordPage.path)
class ForgotPasswordRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ForgotPasswordPage();
  }
}

@TypedGoRoute<VerifyEmailRoute>(path: VerifyEmailPage.path)
class VerifyEmailRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const VerifyEmailPage();
  }
}

@TypedStatefulShellRoute<DashboardRoute>(branches: [
  TypedStatefulShellBranch(
    routes: [
      TypedGoRoute<StrikeRoute>(path: StrikePage.path),
    ],
  ),
  TypedStatefulShellBranch(
    routes: [
      TypedGoRoute<HomeRoute>(path: HomePage.path),
    ],
  ),
  TypedStatefulShellBranch(
    routes: [
      TypedGoRoute<SettingsRoute>(path: SettingsPage.path),
    ],
  ),
])
class DashboardRoute extends StatefulShellRouteData {
  @override
  Widget builder(BuildContext context, GoRouterState state,
      StatefulNavigationShell navigationShell) {
    return DashboardPage(router: navigationShell);
  }
}

class HomeRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomePage();
  }
}

class StrikeRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const StrikePage();
  }
}

class SettingsRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage();
  }
}

@TypedGoRoute<UpdateProfileRoute>(path: UpdateProfilePage.path)
class UpdateProfileRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UpdateProfilePage();
  }
}

@TypedGoRoute<UpdateScheduleRoute>(path: UpdateSchedulePage.path)
class UpdateScheduleRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UpdateSchedulePage();
  }
}

@TypedGoRoute<NotificationRoute>(path: NotificationPage.path)
class NotificationRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const NotificationPage();
  }
}

@TypedGoRoute<FaqRoute>(path: FaqPage.path)
class FaqRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FaqPage();
  }
}

@TypedGoRoute<LegalPoliciesRoute>(path: LegalPoliciesPage.path)
class LegalPoliciesRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LegalPoliciesPage();
  }
}

@TypedGoRoute<PolicyDetailRoute>(path: PolicyDetailPage.path)
class PolicyDetailRoute extends GoRouteData {
  final PolicyModel $extra;

  PolicyDetailRoute({required this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PolicyDetailPage(policy: $extra);
  }
}
