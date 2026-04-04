import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_expense_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isAuth = state.matchedLocation == '/auth';
      if (user == null && !isAuth) return '/auth';
      if (user != null && isAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/groups',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GroupsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => GroupDetailScreen(
                  groupId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/add-expense',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: AddExpenseScreen(
            groupId: state.uri.queryParameters['groupId'],
          ),
        ),
      ),
    ],
  );
});
