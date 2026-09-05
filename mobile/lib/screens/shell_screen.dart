import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/accounts')) return 2;
    if (location.startsWith('/groups')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                context.go('/transactions');
                break;
              case 2:
                context.go('/accounts');
                break;
              case 3:
                context.go('/groups');
                break;
              case 4:
                context.go('/profile');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance_rounded),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
