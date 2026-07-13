import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

/// Notifies GoRouter when login state changes.
class AuthNotifier extends ChangeNotifier {
  bool get isLoggedIn => ApiService.isLoggedIn;

  Future<void> init() => ApiService.init();

  void refresh() => notifyListeners();

  Future<void> signOut() async {
    await ApiService.signOut();
    notifyListeners();
  }
}

final authNotifier = AuthNotifier();
