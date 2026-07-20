import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_landing_screen.dart';
import '../../features/admin/presentation/screens/event_approval_screen.dart';
import '../../features/admin/presentation/screens/role_promotion_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/events/presentation/screens/calendar.dart';
import '../../features/events/presentation/screens/created_events_screen.dart';
import '../../features/events/presentation/screens/dashboard.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/previous_registration.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/theme_settings_screen.dart';
import '../constants/roles.dart';
import '../../shared/widgets/main_shell.dart';

/// Central navigation paths. Use these instead of hardcoding strings at call
/// sites so the route map stays a single source of truth.
class Routes {
  const Routes._();

  static const String splash = '/splash';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  // Bottom-nav shell branches.
  static const String calendar = '/calendar';
  static const String createdEvents = '/created-events';
  static const String dashboard = '/dashboard';
  static const String events = '/events';
  static const String settings = '/settings';

  // Full-screen sub-screens pushed over the shell.
  static const String editProfile = '/settings/edit-profile';
  static const String previousRegistrations = '/settings/previous-registrations';
  static const String theme = '/settings/theme';
  static const String admin = '/settings/admin';
  static const String adminApprovals = '/settings/admin/approvals';
  static const String adminRoles = '/settings/admin/roles';
}

/// Whether [role] may create events (and therefore see the Created Events tab).
bool _canManageEvents(String? role) =>
    role == Roles.organizer ||
    role == Roles.faculty ||
    role == Roles.superAdmin;

/// Root navigator. Sub-screens attach to this so they render full-screen OVER
/// the bottom navigation bar (matching the previous MaterialPageRoute pushes).
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds the app router. Takes the shared [AuthProvider] instance so the
/// redirect can gate on auth state and re-run whenever it changes
/// (AuthProvider is a ChangeNotifier, so it doubles as the refreshListenable).
GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final loc = state.matchedLocation;
      final atAuthScreen = loc == Routes.signIn ||
          loc == Routes.signUp ||
          loc == Routes.forgotPassword;
      // The splash owns its own exit (it holds for its animation, then hands
      // off once auth resolves). Never redirect away from it, so the animation
      // isn't cut short when a restored session resolves quickly.
      if (loc == Routes.splash) return null;

      // Session still restoring elsewhere: leave the current screen as-is.
      if (status == AuthStatus.unknown) return null;

      if (status == AuthStatus.unauthenticated) {
        return atAuthScreen ? null : Routes.signIn;
      }

      // Authenticated: bounce off the auth screens into the app.
      if (atAuthScreen) return Routes.dashboard;

      // Role-gate the Created Events tab against deep links and role changes.
      if (loc == Routes.createdEvents &&
          !_canManageEvents(auth.currentUser?.role)) {
        return Routes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calendar,
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          // Branch 1: Created Events. Always defined so branch indices stay
          // fixed; MainShell + the redirect gate its visibility to organizers
          // and up.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.createdEvents,
                builder: (context, state) => const CreatedEventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.events,
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'edit-profile',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'previous-registrations',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        const PreviousRegisteredEventsScreen(),
                  ),
                  GoRoute(
                    path: 'theme',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const ThemeSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'admin',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AdminLandingScreen(),
                    routes: [
                      GoRoute(
                        path: 'approvals',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) =>
                            const EventApprovalScreen(),
                      ),
                      GoRoute(
                        path: 'roles',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) =>
                            const RolePromotionScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
