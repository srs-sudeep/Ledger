import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../currency_format.dart';
import '../models/models.dart';

class ApiService {
  static const _tokenKey = 'ledger_token';
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static String? _token;
  static String? _currentUserId;
  static String? _currentEmail;

  static String get baseUrl => _baseUrl;
  static String? get token => _token;
  static String? get currentUserId => _currentUserId;
  static String? get currentEmail => _currentEmail;
  static bool get isLoggedIn => _token != null;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token != null) {
      try {
        await getProfile();
      } catch (_) {
        await signOut();
      }
    }
  }

  static Future<void> _saveToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final http.Response res;
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'PATCH':
        res = await http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported method');
    }
    if (res.statusCode >= 400) {
      String msg = res.reasonPhrase ?? 'Request failed';
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['detail'] != null) {
          msg = data['detail'] is String
              ? data['detail'] as String
              : jsonEncode(data['detail']);
        }
      } catch (_) {}
      throw Exception(msg);
    }
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  // Auth
  static Future<void> signIn(String email, String password) async {
    final data = await _request('POST', '/api/auth/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await _saveToken(data['access_token'] as String);
    await getProfile();
  }

  static Future<void> signUp(String email, String password, String fullName) async {
    final data = await _request('POST', '/api/auth/register', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
    }) as Map<String, dynamic>;
    await _saveToken(data['access_token'] as String);
    await getProfile();
  }

  static Future<void> signOut() async {
    await _saveToken(null);
    _currentUserId = null;
    _currentEmail = null;
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  static const String _googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

  static Future<void> signInWithGoogle() async {
    if (_googleClientId.isEmpty) {
      throw Exception(
        'Google sign-in not configured. Pass GOOGLE_CLIENT_ID via --dart-define.',
      );
    }
    final google = GoogleSignIn(
      serverClientId: _googleClientId,
      scopes: const ['email', 'profile'],
    );
    final account = await google.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception('Could not get Google ID token');
    }
    final data = await _request('POST', '/api/auth/google', body: {
      'id_token': idToken,
    }) as Map<String, dynamic>;
    await _saveToken(data['access_token'] as String);
    await getProfile();
  }

  // Profile
  static Future<Profile?> getProfile() async {
    if (_token == null) return null;
    final data = await _request('GET', '/api/auth/me') as Map<String, dynamic>;
    _currentUserId = data['id'] as String;
    _currentEmail = data['email'] as String?;
    return Profile.fromJson(data);
  }

  static Future<void> updateProfile({String? fullName, String? currency}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (currency != null) updates['default_currency'] = currency;
    if (updates.isEmpty) return;
    await _request('PATCH', '/api/auth/me', body: updates);
  }

  // Categories
  static Future<List<Category>> getCategories() async {
    final data = await _request('GET', '/api/categories') as List;
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Personal Expenses
  static Future<List<Expense>> getPersonalExpenses({int limit = 20}) async {
    final data = await _request('GET', '/api/expenses?personal=true&limit=$limit') as List;
    return data.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> addPersonalExpense({
    required String title,
    required int amount,
    String? categoryId,
    required String date,
    String? notes,
    String? currency,
    String? accountId,
  }) async {
    await _request('POST', '/api/expenses', body: {
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date,
      'notes': notes,
      'currency': currency ?? kDefaultCurrency,
      'account_id': accountId,
    });
  }

  // Groups
  static Future<Group> createGroup({
    required String name,
    required String type,
    required String currency,
  }) async {
    final data = await _request('POST', '/api/groups', body: {
      'name': name,
      'type': type,
      'currency': currency,
    }) as Map<String, dynamic>;
    return Group.fromJson(data);
  }

  static Future<Group> getGroup(String id) async {
    final data = await _request('GET', '/api/groups/$id') as Map<String, dynamic>;
    return Group.fromJson(data);
  }

  static Future<String> inviteMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) throw Exception('Enter an email address.');
    final data = await _request('POST', '/api/groups/$groupId/members', body: {
      'email': normalized,
    }) as Map<String, dynamic>;
    final profiles = data['profiles'] as Map<String, dynamic>?;
    return profiles?['full_name'] as String? ?? email;
  }

  static Future<void> removeMember(String membershipId, String groupId) async {
    await _request('DELETE', '/api/groups/$groupId/members/$membershipId');
  }

  static Future<List<Map<String, dynamic>>> getUserGroups() async {
    final data = await _request('GET', '/api/groups') as List;
    return data.map((g) {
      final group = Map<String, dynamic>.from(g as Map<String, dynamic>);
      final count = group['member_count'] as int? ?? 0;
      return {
        'group_id': group['id'],
        'role': group['role'],
        'groups': {
          ...group,
          'group_members': [
            {'count': count},
          ],
        },
      };
    }).toList();
  }

  static Future<List<Expense>> getGroupExpenses(String groupId) async {
    final data =
        await _request('GET', '/api/expenses?group_id=$groupId&limit=200') as List;
    return data.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final data =
        await _request('GET', '/api/groups/$groupId/members') as List;
    return data
        .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addGroupExpense({
    required String title,
    required int amount,
    String? categoryId,
    required String date,
    required String groupId,
    required String payerId,
    required List<Map<String, dynamic>> splits,
  }) async {
    await _request('POST', '/api/expenses', body: {
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date,
      'group_id': groupId,
      'payer_id': payerId,
      'splits': splits
          .map((s) => {
                'user_id': s['user_id'],
                'owed_amount': s['owed_amount'],
                'split_type': s['split_type'] ?? 'equal',
              })
          .toList(),
    });
  }

  static Future<List<SimplifiedTransaction>> getSimplifiedDebts(
      String groupId) async {
    try {
      final data = await _request('POST', '/api/groups/$groupId/simplify-debts')
          as Map<String, dynamic>;
      final txns = data['transactions'] as List? ?? [];
      return txns
          .map((t) => SimplifiedTransaction.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> settleUp({
    required String fromUserId,
    required String toUserId,
    required int amount,
    required String groupId,
  }) async {
    await _request('POST', '/api/groups/$groupId/settlements', body: {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'status': 'completed',
    });
  }

  // Dashboard Aggregates
  static Future<int> getTotalOwedToMe() async {
    final data =
        await _request('GET', '/api/dashboard/summary') as Map<String, dynamic>;
    return data['owed_to_me'] as int? ?? 0;
  }

  static Future<int> getTotalIOwe() async {
    final data =
        await _request('GET', '/api/dashboard/summary') as Map<String, dynamic>;
    return data['i_owe'] as int? ?? 0;
  }

  // Accounts
  static Future<List<Account>> getAccounts() async {
    final data = await _request('GET', '/api/accounts') as List;
    return data.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> addAccount({
    required String name,
    required String type,
    required int balance,
    required String currency,
    String? color,
  }) async {
    await _request('POST', '/api/accounts', body: {
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'color': color,
    });
  }

  static Future<void> deleteAccount(String id) async {
    await _request('DELETE', '/api/accounts/$id');
  }

  // Income
  static Future<List<Income>> getRecentIncome({int limit = 10}) async {
    final data = await _request('GET', '/api/income?limit=$limit') as List;
    return data.map((e) => Income.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> addIncome({
    required int amount,
    required String source,
    required String date,
    String? accountId,
    String? currency,
    String? notes,
  }) async {
    await _request('POST', '/api/income', body: {
      'amount': amount,
      'source': source,
      'date': date,
      'account_id': accountId,
      'currency': currency ?? kDefaultCurrency,
      'notes': notes,
    });
  }
}
