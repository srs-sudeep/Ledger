import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  return ApiService.getProfile();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ApiService.getCategories();
});

final personalExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ApiService.getPersonalExpenses(limit: 50);
});

final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ApiService.getPersonalExpenses(limit: 5);
});

final userGroupsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ApiService.getUserGroups();
});

final groupProvider =
    FutureProvider.family<Group, String>((ref, groupId) async {
  return ApiService.getGroup(groupId);
});

final totalOwedToMeProvider = FutureProvider<int>((ref) async {
  return ApiService.getTotalOwedToMe();
});

final totalIOweProvider = FutureProvider<int>((ref) async {
  return ApiService.getTotalIOwe();
});

final groupExpensesProvider =
    FutureProvider.family<List<Expense>, String>((ref, groupId) async {
  return ApiService.getGroupExpenses(groupId);
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  return ApiService.getGroupMembers(groupId);
});

final simplifiedDebtsProvider =
    FutureProvider.family<List<SimplifiedTransaction>, String>(
        (ref, groupId) async {
  return ApiService.getSimplifiedDebts(groupId);
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return ApiService.getAccounts();
});

final recentIncomeProvider = FutureProvider<List<Income>>((ref) async {
  return ApiService.getRecentIncome();
});
