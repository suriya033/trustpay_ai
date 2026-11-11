class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;
  final String bio;
  final List<String> skills;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar = '',
    this.bio = '',
    this.skills = const [],
  });

  bool get isClient => role == 'client';
  bool get isFreelancer => role == 'freelancer';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'client',
      avatar: json['avatar'] ?? '',
      bio: json['bio'] ?? '',
      skills: json['skills'] != null
          ? List<String>.from(json['skills'])
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'bio': bio,
      'skills': skills,
    };
  }
}
