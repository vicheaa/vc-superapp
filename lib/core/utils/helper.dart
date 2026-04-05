import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/logger.dart';

class HelpersUtils {
  HelpersUtils._();

  /// Safely decode a JSON string into a typed object.
  static T? jsonToObject<T>(
    String jsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return fromJson(jsonData);
    } catch (e) {
      AppLogger.error('Error converting JSON to object', error: e, tag: 'HELPERS');
      return null;
    }
  }

  /// Load a bitmap asset for use as a Google Maps marker icon.
  static Future<BitmapDescriptor> getBitmapAssets(String assetPath) async {
    final asset = await rootBundle.load(assetPath);
    final icon = BitmapDescriptor.bytes(asset.buffer.asUint8List());
    return icon;
  }
}
