import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/auth/pages/pages.dart';
import 'package:gigways/features/community/models/post_model.dart';
import 'package:gigways/features/dashboard/pages/pages.dart';
import 'package:gigways/features/home/pages/pages.dart';
import 'package:gigways/features/onboarding/pages/pages.dart';
import 'package:gigways/features/setting/models/policy_model.dart';
import 'package:gigways/features/setting/pages/pages.dart';
import 'package:gigways/features/strike/pages/pages.dart';
import 'package:gigways/features/community/pages/pages.dart';
import 'package:gigways/routers/auth_router_helper.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    // refreshListenable:
    //     GoRouterRefreshStream(ref.read(authNotifierProvider.notifier).stream),
    initialLocation: SplashPage.path,
    routes: $appRoutes,
    debugLogDiagnostics: true,
    // redirect: (context, state) {
    // Get the current auth state
    // final isAuthenticated = authState.state == AuthState.authenticated;
    // final needsState = authState.state == AuthState.needsState;
    // final isLoading = authState.state == AuthState.loading ||
    //     authState.state == AuthState.initial;

    // // Current path
    // final currentPath = state.matchedLocation;

    // // Paths that don't require authentication
    // final noAuthPaths = [SplashPage.path, OnboardingPage.path];

    // // If the auth state is still loading, allow current navigation
    // if (isLoading) {
    //   return null;
    // }

    // // If user is authenticated
    // if (isAuthenticated) {
    //   // If they're trying to access login or onboarding, redirect to home
    //   if (noAuthPaths.contains(currentPath)) {
    //     return HomePage.path;
    //   }

    //   // Otherwise allow navigation
    //   return null;
    // }

    // // If user needs to select a state
    // if (needsState) {
    //   // Allow them to be on the onboarding page
    //   if (currentPath == OnboardingPage.path) {
    //     return null;
    //   }

    //   // Redirect to onboarding for state selection
    //   return OnboardingPage.path;
    // }

    // // If not authenticated, allow access to non-auth paths
    // if (noAuthPaths.contains(currentPath)) {
    //   return null;
    // }

    // // Otherwise redirect to onboarding
    // return OnboardingPage.path;

    // },
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
      TypedGoRoute<CommunityRoute>(path: CommunityPage.path),
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

@TypedGoRoute<CommentRoute>(path: CommentsPage.path)
class CommentRoute extends GoRouteData {
  final PostModel $extra;

  CommentRoute({required this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CommentsPage(post: $extra);
  }
}
