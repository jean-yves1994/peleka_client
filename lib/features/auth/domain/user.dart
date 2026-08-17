class User {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final String role;
  final String status;
  final String? avatarUrl;
  final String customerType;
  final bool contractCustomer;
  final double creditLimit;
  final double outstandingBalance;

  const User({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.customerType = 'standard',
    this.contractCustomer = false,
    this.creditLimit = 0,
    this.outstandingBalance = 0,
  });

  factory User.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => v == null
        ? 0
        : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return User(
      id: j['id'] as String,
      email: j['email'] as String?,
      phone: j['phone'] as String?,
      fullName: j['full_name'] as String? ?? '',
      role: j['role'] as String? ?? 'customer',
      status: j['status'] as String? ?? 'active',
      avatarUrl: j['avatar_url'] as String?,
      customerType: j['customer_type']?.toString() ?? (j['contract_customer'] == true ? 'premier' : 'standard'),
      contractCustomer: j['contract_customer'] == true,
      creditLimit: d(j['credit_limit']),
      outstandingBalance: d(j['outstanding_balance']),
    );
  }

  bool get isPremier => customerType == 'premier' || contractCustomer;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'full_name': fullName,
    'role': role,
    'status': status,
    'avatar_url': avatarUrl,
    'customer_type': customerType,
    'contract_customer': contractCustomer,
    'credit_limit': creditLimit,
    'outstanding_balance': outstandingBalance,
  };
}
