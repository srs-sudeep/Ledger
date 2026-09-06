import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _initializedLinks = false;

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    if (!_initializedLinks) {
      _initializedLinks = true;
      _initAppLinks(router);
    }

    return MaterialApp.router(
      title: 'Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }

  Future<void> _initAppLinks(GoRouter router) async {
    final appLinks = AppLinks();
    try {
      final initialUri = await appLinks.getInitialLink();
      _handleIncomingUri(router, initialUri);
    } catch (_) {}
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(router, uri);
    });
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
