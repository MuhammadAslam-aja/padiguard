import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'constants.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../core/providers/core_providers.dart';

// Import Pages
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard_petani/presentation/pages/petani_shell_layout.dart';
import '../features/dashboard_petani/presentation/pages/petani_home_page.dart';
import '../features/detection/presentation/pages/detection_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/admin/presentation/pages/admin_shell_layout.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/admin_users_page.dart';
import '../features/admin/presentation/pages/admin_detections_page.dart';
import '../features/admin/presentation/pages/admin_dataset_page.dart';

/// Key navigator root — diekspos agar bisa digunakan untuk menampilkan
/// SnackBar/notifikasi global setelah navigasi (misal setelah login).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _petaniShellKey = GlobalKey<NavigatorState>(debugLabel: 'petaniShell');
final GlobalKey<NavigatorState> _adminShellKey  = GlobalKey<NavigatorState>(debugLabel: 'adminShell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final sharedPrefs = ref.watch(sharedPrefsProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Petani Shell (Bottom Navigation)
      ShellRoute(
        navigatorKey: _petaniShellKey,
        builder: (context, state, child) {
          return PetaniShellLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/petani/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: PetaniHomePage()),
          ),
          GoRoute(
            path: '/petani/scan',
            pageBuilder: (context, state) => const NoTransitionPage(child: DetectionPage()),
          ),
          GoRoute(
            path: '/petani/history',
            pageBuilder: (context, state) => const NoTransitionPage(child: HistoryPage()),
          ),
          GoRoute(
            path: '/petani/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage(isAdmin: false)),
          ),
        ],
      ),

      // Admin Shell (Bottom/Drawer Navigation)
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) {
          return AdminShellLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboardPage()),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminUsersPage()),
          ),
          GoRoute(
            path: '/admin/detections',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminDetectionsPage()),
          ),
          GoRoute(
            path: '/admin/dataset',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminDatasetPage()),
          ),
          GoRoute(
            path: '/admin/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage(isAdmin: true)),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      
      // Determine if auth check is complete
      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return null; // Stay on splash while loading
      }

      final isFirstTime = sharedPrefs.getBool(AppConstants.keyIsFirstTime, defaultValue: true);
      final isLoggedIn = authState.status == AuthStatus.authenticated;

      // 1. If not logged in, force login or onboarding
      if (!isLoggedIn) {
        if (isFirstTime) {
          if (loc == '/onboarding') return null;
          return '/onboarding';
        }
        if (loc == '/login' || loc == '/register') return null;
        return '/login';
      }

      // 2. If logged in, prevent visiting login/register/onboarding/splash/root
      final role = authState.user?.role ?? 'petani';
      if (loc == '/' || loc == '/login' || loc == '/register' || loc == '/onboarding' || loc == '/splash') {
        return role == 'admin' ? '/admin/dashboard' : '/petani/home';
      }

      // 3. Redirect base shell paths (/petani, /petani/, /admin, /admin/) to default home/dashboard pages
      if (loc == '/petani' || loc == '/petani/') {
        return role == 'admin' ? '/admin/dashboard' : '/petani/home';
      }
      if (loc == '/admin' || loc == '/admin/') {
        return role == 'admin' ? '/admin/dashboard' : '/petani/home';
      }

      // 4. Prevent farmers from accessing admin areas
      if (loc.startsWith('/admin') && role != 'admin') {
        return '/petani/home';
      }

      // 5. Prevent admins from accessing farmer areas
      if (loc.startsWith('/petani') && role != 'petani') {
        return '/admin/dashboard';
      }

      return null; // Allow path
    },
  );
});
