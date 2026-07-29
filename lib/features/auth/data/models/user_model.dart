class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'petani' or 'admin'
  final String createdAt;
  final String avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'petani',
      createdAt: json['createdAt'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? avatar,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
      avatar: avatar ?? this.avatar,
    );
  }
}
