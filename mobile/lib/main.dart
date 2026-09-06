import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';
import 'providers/auth_notifier.dart';
import 'router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authNotifier.init();
  runApp(const ProviderScope(child: LedgerApp()));
}

class LedgerApp extends ConsumerStatefulWidget {
  const LedgerApp({super.key});

  @override
  ConsumerState<LedgerApp> createState() => _LedgerAppState();
}

class _LedgerAppState extends ConsumerState<LedgerApp> {
  StreamSubscription<Uri>? _linkSub;
  bool _initializedPlatformHooks = false;
  final QuickActions _quickActions = const QuickActions();

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    if (!_initializedPlatformHooks) {
      _initializedPlatformHooks = true;
      _initPlatformHooks(router);
    }

    return MaterialApp.router(
      title: 'Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }

  Future<void> _initPlatformHooks(GoRouter router) async {
    await _quickActions.initialize((shortcutType) {
      _handleShortcut(router, shortcutType);
    });
    await _quickActions.setShortcutItems(const <ShortcutItem>[
      ShortcutItem(type: 'quick_wallet', localizedTitle: 'Wallet payment'),
      ShortcutItem(type: 'quick_paypay', localizedTitle: 'PayPay payment'),
      ShortcutItem(type: 'quick_suica', localizedTitle: 'Suica payment'),
      ShortcutItem(type: 'quick_cash', localizedTitle: 'Cash payment'),
    ]);

    final appLinks = AppLinks();
    try {
      final initialUri = await appLinks.getInitialLink();
      _handleIncomingUri(router, initialUri);
    } catch (_) {}
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(router, uri);
    });
  }

  void _handleShortcut(GoRouter router, String shortcutType) {
    const routeByShortcut = <String, String>{
      'quick_wallet': 'wallet',
      'quick_paypay': 'paypay',
      'quick_suica': 'suica',
      'quick_cash': 'cash',
    };
    final source = routeByShortcut[shortcutType];
    if (source == null) return;
    router.go('/quick-add?source=$source');
  }

  void _handleIncomingUri(GoRouter router, Uri? uri) {
    if (uri == null) return;
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
    ];
    final isQuickAdd = segments.contains('quick-add');
    if (!isQuickAdd) return;
    final source = uri.queryParameters['source'];
    final query = source == null || source.isEmpty ? '' : '?source=$source';
    router.go('/quick-add$query');
  }
}
