class User {
  final int id;
  final String name;
  final String username;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
    };
  }
}