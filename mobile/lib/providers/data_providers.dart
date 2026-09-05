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

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  return ApiService.getDashboardSummary();
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

final transactionsProvider =
    FutureProvider.family<List<LedgerTransaction>, LedgerQuery>((ref, query) async {
  return ApiService.getTransactions(query);
});

final transactionSummaryProvider = FutureProvider.family<LedgerTransactionSummary, LedgerQuery>(
  (ref, query) async {
    return ApiService.getTransactionSummary(query);
  },
);

final recentTransactionsProvider = FutureProvider<List<LedgerTransaction>>((ref) async {
  return ApiService.getTransactions(const LedgerQuery(pageSize: 8));
});

final incomeProvider = FutureProvider.family<List<Income>, EntryQuery>((ref, query) async {
  return ApiService.getIncome(query);
});

final incomeCountProvider = FutureProvider.family<int, EntryQuery>((ref, query) async {
  return ApiService.getIncomeCount(query);
});

final transferProvider = FutureProvider.family<List<Transfer>, EntryQuery>((ref, query) async {
  return ApiService.getTransfers(query);
});

final transferCountProvider = FutureProvider.family<int, EntryQuery>((ref, query) async {
  return ApiService.getTransferCount(query);
});

final recentIncomeProvider = FutureProvider<List<Income>>((ref) async {
  return ApiService.getIncome(const EntryQuery(pageSize: 5));
});

final recentTransfersProvider = FutureProvider<List<Transfer>>((ref) async {
  return ApiService.getTransfers(const EntryQuery(pageSize: 5));
});

final analyticsProvider = FutureProvider<AnalyticsSummary>((ref) async {
  return ApiService.getAnalyticsSummary();
});
