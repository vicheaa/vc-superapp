class MiniAppManifest {
  const MiniAppManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.downloadUrl,
    required this.iconUrl,
  });

  final String id;
  final String name;
  final String version;
  final String description;
  final String downloadUrl;
  final String iconUrl;

  factory MiniAppManifest.fromJson(Map<String, dynamic> json) {
    return MiniAppManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      downloadUrl: json['downloadUrl'] as String,
      iconUrl: json['iconUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'downloadUrl': downloadUrl,
      'iconUrl': iconUrl,
    };
  }
}
