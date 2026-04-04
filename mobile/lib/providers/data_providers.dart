import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  return SupabaseService.getProfile();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return SupabaseService.getCategories();
});

final personalExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return SupabaseService.getPersonalExpenses(limit: 50);
});

final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return SupabaseService.getPersonalExpenses(limit: 5);
});

final userGroupsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getUserGroups();
});

final totalOwedToMeProvider = FutureProvider<int>((ref) async {
  return SupabaseService.getTotalOwedToMe();
});

final totalIOweProvider = FutureProvider<int>((ref) async {
  return SupabaseService.getTotalIOwe();
});

final groupExpensesProvider =
    FutureProvider.family<List<Expense>, String>((ref, groupId) async {
  return SupabaseService.getGroupExpenses(groupId);
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  return SupabaseService.getGroupMembers(groupId);
});

final simplifiedDebtsProvider =
    FutureProvider.family<List<SimplifiedTransaction>, String>(
        (ref, groupId) async {
  return SupabaseService.getSimplifiedDebts(groupId);
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return SupabaseService.getAccounts();
});

final recentIncomeProvider = FutureProvider<List<Income>>((ref) async {
  return SupabaseService.getRecentIncome();
});
