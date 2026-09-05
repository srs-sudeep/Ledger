import '../currency_format.dart';

class Profile {
  final String id;
  final String? fullName;
  final String? phonePrimary;
  final String? phoneSecondary;
  final String? email;
  final String? avatarUrl;
  final String defaultCurrency;

  Profile({
    required this.id,
    this.fullName,
    this.phonePrimary,
    this.phoneSecondary,
    this.email,
    this.avatarUrl,
    this.defaultCurrency = kDefaultCurrency,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        phonePrimary: json['phone_primary'] as String?,
        phoneSecondary: json['phone_secondary'] as String?,
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        defaultCurrency:
            json['default_currency'] as String? ?? kDefaultCurrency,
      );
}

class Category {
  final String id;
  final String name;
  final String icon;
  final String? color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String?,
      );
}

class Group {
  final String id;
  final String name;
  final String type;
  final String createdBy;
  final String createdAt;
  final String currency;

  Group({
    required this.id,
    required this.name,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    this.currency = kDefaultCurrency,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        createdBy: json['created_by'] as String,
        createdAt: json['created_at'] as String,
        currency: json['currency'] as String? ?? kDefaultCurrency,
      );
}

class Expense {
  final String id;
  final String title;
  final int amount;
  final String currency;
  final String? categoryId;
  final String date;
  final String payerId;
  final String? groupId;
  final String? notes;
  final Category? category;
  final Profile? payer;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    this.currency = kDefaultCurrency,
    this.categoryId,
    required this.date,
    required this.payerId,
    this.groupId,
    this.notes,
    this.category,
    this.payer,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: json['amount'] as int,
        currency: json['currency'] as String? ?? kDefaultCurrency,
        categoryId: json['category_id'] as String?,
        date: json['date'] as String,
        payerId: json['payer_id'] as String,
        groupId: json['group_id'] as String?,
        notes: json['notes'] as String?,
        category: json['category'] != null
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : json['categories'] != null
            ? Category.fromJson(
                (json['categories'] is List
                        ? (json['categories'] as List).first
                        : json['categories'])
                    as Map<String, dynamic>,
              )
            : null,
        payer: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );

  String get formattedAmount => formatMoneyCents(amount, currency);
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final Profile? profile;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.profile,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        userId: json['user_id'] as String,
        role: json['role'] as String,
        profile: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );
}

class SimplifiedTransaction {
  final String from;
  final String to;
  final int amount;

  SimplifiedTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });

  factory SimplifiedTransaction.fromJson(Map<String, dynamic> json) =>
      SimplifiedTransaction(
        from: json['from'] as String,
        to: json['to'] as String,
        amount: json['amount'] as int,
      );
}

class Account {
  final String id;
  final String userId;
  final String name;
  final String type;
  final int balance;
  final String currency;
  final String? icon;
  final String? color;
  final bool isDefault;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = kDefaultCurrency,
    this.icon,
    this.color,
    this.isDefault = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        balance: json['balance'] as int,
        currency: json['currency'] as String? ?? kDefaultCurrency,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
      );

  String get formattedBalance => formatMoneyCents(balance, currency);

  String get typeLabel {
    switch (type) {
      case 'bank':
        return 'Bank Account';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'wallet':
        return 'Wallet';
      case 'cash':
        return 'Cash';
      default:
        return 'Other';
    }
  }
}

class Income {
  final String id;
  final String userId;
  final String? accountId;
  final int amount;
  final String currency;
  final String source;
  final String date;
  final String? notes;

  Income({
    required this.id,
    required this.userId,
    this.accountId,
    required this.amount,
    this.currency = kDefaultCurrency,
    required this.source,
    required this.date,
    this.notes,
  });

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        accountId: json['account_id'] as String?,
        amount: json['amount'] as int,
        currency: json['currency'] as String? ?? kDefaultCurrency,
        source: json['source'] as String,
        date: json['date'] as String,
        notes: json['notes'] as String?,
      );
}

class Transfer {
  final String id;
  final String userId;
  final String? fromAccountId;
  final String? toAccountId;
  final int amount;
  final String currency;
  final String date;
  final String? kind;
  final String? notes;

  Transfer({
    required this.id,
    required this.userId,
    this.fromAccountId,
    this.toAccountId,
    required this.amount,
    this.currency = kDefaultCurrency,
    required this.date,
    this.kind,
    this.notes,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) => Transfer(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fromAccountId: json['from_account_id'] as String?,
        toAccountId: json['to_account_id'] as String?,
        amount: json['amount'] as int,
        currency: json['currency'] as String? ?? kDefaultCurrency,
        date: json['date'] as String,
        kind: json['kind'] as String?,
        notes: json['notes'] as String?,
      );
}

class DashboardSummary {
  final int netWorth;
  final int assetTotal;
  final int liabilityTotal;
  final int groupNet;
  final int owedToMe;
  final int iOwe;
  final int monthlySpend;

  DashboardSummary({
    required this.netWorth,
    required this.assetTotal,
    required this.liabilityTotal,
    required this.groupNet,
    required this.owedToMe,
    required this.iOwe,
    required this.monthlySpend,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        netWorth: json['net_worth'] as int? ?? 0,
        assetTotal: json['asset_total'] as int? ?? 0,
        liabilityTotal: json['liability_total'] as int? ?? 0,
        groupNet: json['group_net'] as int? ?? 0,
        owedToMe: json['owed_to_me'] as int? ?? 0,
        iOwe: json['i_owe'] as int? ?? 0,
        monthlySpend: json['monthly_spend'] as int? ?? 0,
      );
}

class LedgerCategoryTotal {
  final String? categoryId;
  final String categoryName;
  final String? color;
  final int total;

  LedgerCategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.total,
  });

  factory LedgerCategoryTotal.fromJson(Map<String, dynamic> json) =>
      LedgerCategoryTotal(
        categoryId: json['category_id'] as String?,
        categoryName: json['category_name'] as String? ?? 'Uncategorized',
        color: json['color'] as String?,
        total: json['total'] as int? ?? 0,
      );
}

class LedgerMerchantTotal {
  final String name;
  final int total;

  LedgerMerchantTotal({
    required this.name,
    required this.total,
  });

  factory LedgerMerchantTotal.fromJson(Map<String, dynamic> json) =>
      LedgerMerchantTotal(
        name: json['name'] as String? ?? 'Unknown',
        total: json['total'] as int? ?? 0,
      );
}

class LedgerTransactionSummary {
  final int transactionCount;
  final int incomeTotal;
  final int expenseTotal;
  final int transferInTotal;
  final int transferOutTotal;
  final int netFlow;
  final List<LedgerCategoryTotal> topCategories;
  final List<LedgerMerchantTotal> topMerchants;

  LedgerTransactionSummary({
    required this.transactionCount,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.transferInTotal,
    required this.transferOutTotal,
    required this.netFlow,
    required this.topCategories,
    required this.topMerchants,
  });

  factory LedgerTransactionSummary.fromJson(Map<String, dynamic> json) =>
      LedgerTransactionSummary(
        transactionCount: json['transaction_count'] as int? ?? 0,
        incomeTotal: json['income_total'] as int? ?? 0,
        expenseTotal: json['expense_total'] as int? ?? 0,
        transferInTotal: json['transfer_in_total'] as int? ?? 0,
        transferOutTotal: json['transfer_out_total'] as int? ?? 0,
        netFlow: json['net_flow'] as int? ?? 0,
        topCategories: ((json['top_categories'] as List?) ?? [])
            .map((e) => LedgerCategoryTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
        topMerchants: ((json['top_merchants'] as List?) ?? [])
            .map((e) => LedgerMerchantTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LedgerTransaction {
  final String id;
  final String txType;
  final String direction;
  final int amount;
  final int signedAmount;
  final String currency;
  final String title;
  final String? merchantOriginal;
  final String? merchantDisplay;
  final String date;
  final String createdAt;
  final String? categoryId;
  final String? categoryName;
  final String? accountId;
  final String? accountName;
  final String? counterpartyAccountId;
  final String? counterpartyAccountName;
  final String? notes;

  LedgerTransaction({
    required this.id,
    required this.txType,
    required this.direction,
    required this.amount,
    required this.signedAmount,
    required this.currency,
    required this.title,
    this.merchantOriginal,
    this.merchantDisplay,
    required this.date,
    required this.createdAt,
    this.categoryId,
    this.categoryName,
    this.accountId,
    this.accountName,
    this.counterpartyAccountId,
    this.counterpartyAccountName,
    this.notes,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) =>
      LedgerTransaction(
        id: json['id'] as String,
        txType: json['tx_type'] as String? ?? 'expense',
        direction: json['direction'] as String? ?? 'outflow',
        amount: json['amount'] as int? ?? 0,
        signedAmount: json['signed_amount'] as int? ?? 0,
        currency: json['currency'] as String? ?? kDefaultCurrency,
        title: json['title'] as String? ?? 'Transaction',
        merchantOriginal: json['merchant_original'] as String?,
        merchantDisplay: json['merchant_display'] as String?,
        date: json['date'] as String,
        createdAt: json['created_at'] as String? ?? '',
        categoryId: json['category_id'] as String?,
        categoryName: json['category_name'] as String?,
        accountId: json['account_id'] as String?,
        accountName: json['account_name'] as String?,
        counterpartyAccountId: json['counterparty_account_id'] as String?,
        counterpartyAccountName: json['counterparty_account_name'] as String?,
        notes: json['notes'] as String?,
      );

  String get formattedSignedAmount =>
      '${signedAmount > 0 ? '+' : signedAmount < 0 ? '-' : ''}${formatMoneyCents(signedAmount.abs(), currency)}';
}

class AnalyticsByMonth {
  final String month;
  final int personal;
  final int group;

  AnalyticsByMonth({
    required this.month,
    required this.personal,
    required this.group,
  });

  factory AnalyticsByMonth.fromJson(Map<String, dynamic> json) =>
      AnalyticsByMonth(
        month: json['month'] as String? ?? '',
        personal: json['personal'] as int? ?? 0,
        group: json['group'] as int? ?? 0,
      );
}

class AnalyticsSummary {
  final int personalTotal;
  final int groupTotal;
  final List<LedgerCategoryTotal> byCategory;
  final List<AnalyticsByMonth> byMonth;

  AnalyticsSummary({
    required this.personalTotal,
    required this.groupTotal,
    required this.byCategory,
    required this.byMonth,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      AnalyticsSummary(
        personalTotal: json['personal_total'] as int? ?? 0,
        groupTotal: json['group_total'] as int? ?? 0,
        byCategory: ((json['by_category'] as List?) ?? [])
            .map((e) => LedgerCategoryTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
        byMonth: ((json['by_month'] as List?) ?? [])
            .map((e) => AnalyticsByMonth.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LedgerQuery {
  final String search;
  final String accountId;
  final String txType;
  final String direction;
  final String categoryId;
  final String fromDate;
  final String toDate;
  final String sort;
  final int page;
  final int pageSize;

  const LedgerQuery({
    this.search = '',
    this.accountId = '',
    this.txType = '',
    this.direction = '',
    this.categoryId = '',
    this.fromDate = '',
    this.toDate = '',
    this.sort = 'date_desc',
    this.page = 1,
    this.pageSize = 25,
  });

  int get offset => (page - 1) * pageSize;

  LedgerQuery copyWith({
    String? search,
    String? accountId,
    String? txType,
    String? direction,
    String? categoryId,
    String? fromDate,
    String? toDate,
    String? sort,
    int? page,
    int? pageSize,
  }) {
    return LedgerQuery(
      search: search ?? this.search,
      accountId: accountId ?? this.accountId,
      txType: txType ?? this.txType,
      direction: direction ?? this.direction,
      categoryId: categoryId ?? this.categoryId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, String> toQueryParameters({bool includePaging = true}) {
    return {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (accountId.isNotEmpty) 'account_id': accountId,
      if (txType.isNotEmpty) 'tx_type': txType,
      if (direction.isNotEmpty) 'direction': direction,
      if (categoryId.isNotEmpty) 'category_id': categoryId,
      if (fromDate.isNotEmpty) 'from_date': fromDate,
      if (toDate.isNotEmpty) 'to_date': toDate,
      if (sort.isNotEmpty) 'sort': sort,
      if (includePaging) 'limit': '$pageSize',
      if (includePaging) 'offset': '$offset',
    };
  }

  @override
  bool operator ==(Object other) {
    return other is LedgerQuery &&
        other.search == search &&
        other.accountId == accountId &&
        other.txType == txType &&
        other.direction == direction &&
        other.categoryId == categoryId &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.sort == sort &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        search,
        accountId,
        txType,
        direction,
        categoryId,
        fromDate,
        toDate,
        sort,
        page,
        pageSize,
      );
}

class EntryQuery {
  final String search;
  final String accountId;
  final String fromDate;
  final String toDate;
  final String sort;
  final int page;
  final int pageSize;

  const EntryQuery({
    this.search = '',
    this.accountId = '',
    this.fromDate = '',
    this.toDate = '',
    this.sort = 'date_desc',
    this.page = 1,
    this.pageSize = 25,
  });

  int get offset => (page - 1) * pageSize;

  EntryQuery copyWith({
    String? search,
    String? accountId,
    String? fromDate,
    String? toDate,
    String? sort,
    int? page,
    int? pageSize,
  }) {
    return EntryQuery(
      search: search ?? this.search,
      accountId: accountId ?? this.accountId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, String> toQueryParameters({bool includePaging = true}) {
    return {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (accountId.isNotEmpty) 'account_id': accountId,
      if (fromDate.isNotEmpty) 'from_date': fromDate,
      if (toDate.isNotEmpty) 'to_date': toDate,
      if (sort.isNotEmpty) 'sort': sort,
      if (includePaging) 'limit': '$pageSize',
      if (includePaging) 'offset': '$offset',
    };
  }

  @override
  bool operator ==(Object other) {
    return other is EntryQuery &&
        other.search == search &&
        other.accountId == accountId &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.sort == sort &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode =>
      Object.hash(search, accountId, fromDate, toDate, sort, page, pageSize);
}
