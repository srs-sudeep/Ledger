import 'package:supabase_flutter/supabase_flutter.dart';
import '../currency_format.dart';
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
    String? currency,
    String? accountId,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    final row = <String, dynamic>{
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date,
      'payer_id': uid,
      'notes': notes,
    };
    if (currency != null) row['currency'] = currency;
    if (accountId != null) row['account_id'] = accountId;
    await client.from('expenses').insert(row);
    if (accountId != null) {
      final acc = await client
          .from('accounts')
          .select('balance')
          .eq('id', accountId)
          .single();
      await client.from('accounts').update({
        'balance': (acc['balance'] as int) - amount,
      }).eq('id', accountId);
    }
  }

  // Groups
  static Future<Group> createGroup({
    required String name,
    required String type,
    required String currency,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not signed in');
    final res = await client
        .from('groups')
        .insert({
          'name': name,
          'type': type,
          'currency': currency,
          'created_by': uid,
        })
        .select()
        .single();
    final group = Group.fromJson(res);
    await client.from('group_members').insert({
      'group_id': group.id,
      'user_id': uid,
      'role': 'admin',
    });
    return group;
  }

  static Future<Group> getGroup(String id) async {
    final data = await client.from('groups').select().eq('id', id).single();
    return Group.fromJson(data);
  }

  static Future<String> inviteMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Enter an email address.');
    }
    final rows = await client
        .from('profiles')
        .select('id, full_name, email')
        .eq('email', normalized)
        .limit(1);
    if (rows.isEmpty) {
      throw Exception(
        'No account with that email. They must register before you can add them.',
      );
    }
    final res = Map<String, dynamic>.from(rows.first as Map);
    final profileId = res['id'] as String;
    final existing = await client
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', profileId);
    if ((existing as List).isNotEmpty) {
      throw Exception('That person is already in this group.');
    }
    await client.from('group_members').insert({
      'group_id': groupId,
      'user_id': profileId,
      'role': 'member',
    });
    return res['full_name'] as String? ?? email;
  }

  static Future<void> removeMember(String membershipId) async {
    await client.from('group_members').delete().eq('id', membershipId);
  }

  static Future<List<Map<String, dynamic>>> getUserGroups() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await client
        .from('group_members')
        .select(
          'group_id, role, groups(id, name, type, currency, created_by, created_at, group_members(count))',
        )
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
    // FK is user_id -> auth.users, not profiles; embed profiles(*) does not resolve.
    final rows = await client
        .from('group_members')
        .select('id, group_id, user_id, role, joined_at')
        .eq('group_id', groupId)
        .order('joined_at', ascending: true);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return [];

    final ids = list.map((r) => r['user_id'] as String).toList();
    final profilesData =
        await client.from('profiles').select().inFilter('id', ids);

    final profilesList =
        List<Map<String, dynamic>>.from(profilesData as List);
    final byId = {
      for (final p in profilesList) p['id'] as String: p,
    };

    return list.map((row) {
      final uid = row['user_id'] as String;
      final merged = Map<String, dynamic>.from(row);
      final p = byId[uid];
      if (p != null) merged['profiles'] = p;
      return GroupMember.fromJson(merged);
    }).toList();
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
    final gRow = await client
        .from('groups')
        .select('currency')
        .eq('id', groupId)
        .single();
    final groupCurrency =
        gRow['currency'] as String? ?? kDefaultCurrency;
    final res = await client
        .from('expenses')
        .insert({
          'title': title,
          'amount': amount,
          'currency': groupCurrency,
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

  // Accounts
  static Future<List<Account>> getAccounts() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await client
        .from('accounts')
        .select()
        .eq('user_id', uid)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Account.fromJson(e)).toList();
  }

  static Future<void> addAccount({
    required String name,
    required String type,
    required int balance,
    required String currency,
    String? color,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    await client.from('accounts').insert({
      'user_id': uid,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'color': color,
    });
  }

  static Future<void> deleteAccount(String id) async {
    await client.from('accounts').delete().eq('id', id);
  }

  // Income
  static Future<List<Income>> getRecentIncome({int limit = 10}) async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await client
        .from('income')
        .select()
        .eq('user_id', uid)
        .order('date', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Income.fromJson(e)).toList();
  }

  static Future<void> addIncome({
    required int amount,
    required String source,
    required String date,
    String? accountId,
    String? currency,
    String? notes,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    await client.from('income').insert({
      'user_id': uid,
      'account_id': accountId,
      'amount': amount,
      'currency': currency ?? kDefaultCurrency,
      'source': source,
      'date': date,
      'notes': notes,
    });
    if (accountId != null) {
      final acc = await client
          .from('accounts')
          .select('balance')
          .eq('id', accountId)
          .single();
      await client.from('accounts').update({
        'balance': (acc['balance'] as int) + amount,
      }).eq('id', accountId);
    }
  }
}
