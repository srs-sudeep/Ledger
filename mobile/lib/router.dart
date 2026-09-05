import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_notifier.dart';
import 'screens/accounts_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/help_screen.dart';
import 'screens/income_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/transfers_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = authNotifier.isLoggedIn;
      final isAuth = state.matchedLocation == '/auth';
      if (!loggedIn && !isAuth) return '/auth';
      if (loggedIn && isAuth) return '/dashboard';
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
            path: '/transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: '/accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => TransactionsScreen(
                  accountId: state.pathParameters['id'],
                  accountName: state.uri.queryParameters['name'],
                ),
              ),
            ],
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
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/income',
        builder: (context, state) => const IncomeListScreen(),
      ),
      GoRoute(
        path: '/transfers',
        builder: (context, state) => const TransfersListScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
    ],
  );
});
