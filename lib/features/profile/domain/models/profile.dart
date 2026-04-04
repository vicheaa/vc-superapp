class Profile {
  const Profile({required this.id});

  final String id;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
    );
  }
}
