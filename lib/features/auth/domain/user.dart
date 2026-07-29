class User {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final String role;
  final String status;
  final String? avatarUrl;
  const User(
      {required this.id,
      this.email,
      this.phone,
      required this.fullName,
      required this.role,
      required this.status,
      this.avatarUrl});
  factory User.fromJson(Map<String, dynamic> j) => User(
      id: j['id'] as String,
      email: j['email'] as String?,
      phone: j['phone'] as String?,
      fullName: j['full_name'] as String,
      role: j['role'] as String,
      status: j['status'] as String,
      avatarUrl: j['avatar_url'] as String?);
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'role': role,
        'status': status,
        'avatar_url': avatarUrl
      };
}
