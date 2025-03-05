
class AuthUser {
  final String id;
  final String? email;
  final String? name;
  final String? avatarPath;
  final String locale;
  final String? username;
  final String? token;

  AuthUser({
    required this.id,
    this.email,
    this.name,
    this.avatarPath,
    this.locale = 'en',
    this.username,
    this.token,
  });

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarPath,
    String? locale,
    String? username,
    String? token,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      locale: locale ?? this.locale,
      username: username ?? this.username,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarPath': avatarPath,
      'locale': locale,
      'username': username,
      'token': token,
    };
  }

  static AuthUser fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      locale: json['locale'] ?? 'en',
      username: json['username'],
      token: json['token'],
    );
  }
}
