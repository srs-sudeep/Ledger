class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String defaultCurrency;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.defaultCurrency = 'USD',
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        defaultCurrency: json['default_currency'] as String? ?? 'USD',
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
    this.currency = 'USD',
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        createdBy: json['created_by'] as String,
        createdAt: json['created_at'] as String,
        currency: json['currency'] as String? ?? 'USD',
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
    this.currency = 'USD',
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
        currency: json['currency'] as String? ?? 'USD',
        categoryId: json['category_id'] as String?,
        date: json['date'] as String,
        payerId: json['payer_id'] as String,
        groupId: json['group_id'] as String?,
        notes: json['notes'] as String?,
        category: json['categories'] != null
            ? Category.fromJson(json['categories'] as Map<String, dynamic>)
            : null,
        payer: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );

  String get formattedAmount {
    final dollars = amount / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }
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
    this.currency = 'USD',
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
        currency: json['currency'] as String? ?? 'USD',
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
      );

  String get formattedBalance {
    final dollars = balance / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

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
    this.currency = 'USD',
    required this.source,
    required this.date,
    this.notes,
  });

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        accountId: json['account_id'] as String?,
        amount: json['amount'] as int,
        currency: json['currency'] as String? ?? 'USD',
        source: json['source'] as String,
        date: json['date'] as String,
        notes: json['notes'] as String?,
      );
}
