class Profile {
  final String id;
  final String fullName;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'] ?? 'Utilisateur Inconnu',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
