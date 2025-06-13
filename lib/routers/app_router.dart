import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/auth/pages/pages.dart';
import 'package:gigways/features/auth/pages/state_selection_page.dart';
import 'package:gigways/features/community/models/post_model.dart';
import 'package:gigways/features/dashboard/pages/pages.dart';
import 'package:gigways/features/home/pages/pages.dart';
import 'package:gigways/features/insights/pages/insights_page.dart';
import 'package:gigways/features/onboarding/pages/pages.dart';
import 'package:gigways/features/setting/models/policy_model.dart';
import 'package:gigways/features/setting/pages/pages.dart';
import 'package:gigways/features/strike/pages/pages.dart';
import 'package:gigways/features/community/pages/pages.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashPage.path,
    routes: $appRoutes,
    debugLogDiagnostics: true,
  );
});

// The rest of your router file remains unchanged
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
  // TypedStatefulShellBranch(
  //   routes: [
  //     TypedGoRoute<CommunityRoute>(path: CommunityPage.path),
  //   ],
  // ),
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

class CommunityRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CommunityPage();
  }
}

class SettingsRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage();
  }
}

@TypedGoRoute<StateSelectionRoute>(path: StateSelectionPage.path)
class StateSelectionRoute extends GoRouteData {
  const StateSelectionRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const StateSelectionPage();
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

@TypedGoRoute<CommentRoute>(path: CommentsPage.path)
class CommentRoute extends GoRouteData {
  final PostModel $extra;

  CommentRoute({required this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CommentsPage(post: $extra);
  }
}

@TypedGoRoute<InsightsRoute>(path: InsightsPage.path)
class InsightsRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const InsightsPage();
  }
}
