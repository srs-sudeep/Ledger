import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  // Auth
  static Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password, String fullName) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  static Future<bool> signInWithGoogle() async {
    final res = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.lyari.mobile://login-callback/',
    );
    return res;
  }

  // Profile
  static Future<Profile?> getProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final data = await client.from('profiles').select().eq('id', uid).single();
    return Profile.fromJson(data);
  }

  static Future<void> updateProfile({String? fullName, String? currency}) async {
    final uid = currentUserId;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (currency != null) updates['default_currency'] = currency;
    if (updates.isNotEmpty) {
      await client.from('profiles').update(updates).eq('id', uid);
    }
  }

  // Categories
  static Future<List<Category>> getCategories() async {
    final data = await client.from('categories').select().order('name');
    return (data as List).map((e) => Category.fromJson(e)).toList();
  }

  // Personal Expenses
  static Future<List<Expense>> getPersonalExpenses({int limit = 20}) async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await client
        .from('expenses')
        .select('*, categories(*)')
        .eq('payer_id', uid)
        .isFilter('group_id', null)
        .order('date', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Expense.fromJson(e)).toList();
  }

  static Future<void> addPersonalExpense({
    required String title,
    required int amount,
    String? categoryId,
    required String date,
    String? notes,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    await client.from('expenses').insert({
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date,
      'payer_id': uid,
      'notes': notes,
    });
  }

  // Groups
  static Future<List<Map<String, dynamic>>> getUserGroups() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await client
        .from('group_members')
        .select('group_id, role, groups(*)')
        .eq('user_id', uid);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Expense>> getGroupExpenses(String groupId) async {
    final data = await client
        .from('expenses')
        .select('*, categories(*), profiles!expenses_payer_id_fkey(*)')
        .eq('group_id', groupId)
        .order('date', ascending: false);
    return (data as List).map((e) => Expense.fromJson(e)).toList();
  }

  static Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final data = await client
        .from('group_members')
        .select('*, profiles(*)')
        .eq('group_id', groupId);
    return (data as List).map((e) => GroupMember.fromJson(e)).toList();
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
    final res = await client
        .from('expenses')
        .insert({
          'title': title,
          'amount': amount,
          'category_id': categoryId,
          'date': date,
          'group_id': groupId,
          'payer_id': payerId,
        })
        .select()
        .single();

    final expenseId = res['id'] as String;
    final splitInserts = splits
        .map((s) => <String, dynamic>{
              'expense_id': expenseId,
              'user_id': s['user_id'],
              'owed_amount': s['owed_amount'],
              'split_type': s['split_type'] ?? 'equal',
            })
        .toList();

    if (splitInserts.isNotEmpty) {
      await client.from('expense_splits').insert(splitInserts);
    }
  }

  // Debt Simplifier
  static Future<List<SimplifiedTransaction>> getSimplifiedDebts(
      String groupId) async {
    try {
      final res = await client.functions.invoke(
        'debt-simplifier',
        body: {'group_id': groupId},
      );
      final data = res.data as Map<String, dynamic>;
      final txns = data['transactions'] as List;
      return txns.map((t) => SimplifiedTransaction.fromJson(t)).toList();
    } catch (_) {
      return [];
    }
  }

  // Settlements
  static Future<void> settleUp({
    required String fromUserId,
    required String toUserId,
    required int amount,
    required String groupId,
  }) async {
    await client.from('settlements').insert({
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'group_id': groupId,
      'status': 'completed',
      'settled_at': DateTime.now().toIso8601String(),
    });
  }

  // Dashboard Aggregates
  static Future<int> getTotalOwedToMe() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final data = await client
        .from('expense_splits')
        .select('owed_amount, expenses!inner(payer_id)')
        .neq('user_id', uid)
        .eq('expenses.payer_id', uid);
    int total = 0;
    for (final row in data) {
      total += (row['owed_amount'] as int?) ?? 0;
    }
    return total;
  }

  static Future<int> getTotalIOwe() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final data = await client
        .from('expense_splits')
        .select('owed_amount, expenses!inner(payer_id)')
        .eq('user_id', uid)
        .neq('expenses.payer_id', uid);
    int total = 0;
    for (final row in data) {
      total += (row['owed_amount'] as int?) ?? 0;
    }
    return total;
  }
}
