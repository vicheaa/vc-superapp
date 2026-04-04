import '../../domain/models/miniapp_manifest.dart';

class MiniAppResponse {
  final List<MiniAppManifest> miniApps;

  MiniAppResponse({required this.miniApps});

  factory MiniAppResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final list = data['miniApps'] as List<dynamic>;
    
    return MiniAppResponse(
      miniApps: list
          .map((e) => MiniAppManifest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
