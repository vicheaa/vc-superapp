import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vc_super_app/data/local/secure_storage.dart';

class HelpersUtils {
  HelpersUtils._();
  static T? jsonToObject<T>(
    String jsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return fromJson(jsonData);
    } catch (e) {
      if (kDebugMode) {
        print('Error converting JSON to object: $e');
      }
      return null;
    }
  }

  static Future<BitmapDescriptor> getBitmapAssets(String assetPath) async {
    final asset = await rootBundle.load(assetPath);
    final icon = BitmapDescriptor.bytes(asset.buffer.asUint8List());
    return icon;
  }

  static bool isAuthenticated(BuildContext context) {
    final token = SecureStorageService().getToken().toString();
    if (token.isEmpty) {
      // HelpersUtils.navigatorState(context).pushNamed(AppPage.LOGIN);
      return false;
    }
    return true;
  }

//   static Future<LocationData> getCurrentLocation() async {
//     final Location location = Location();

//     // Check if location services are enabled
//     bool serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await location.requestService();
//       if (!serviceEnabled) {
//         return Future.error('Location services are disabled.');
//       }
//     }

//     // Request location permission
//     PermissionStatus permissionGranted = await location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) {
//         return Future.error(
//           'Location permissions are denied. Please enable them in settings.',
//         );
//       }
//     }

//     // If permission is permanently denied, ask user to enable manually
//     if (permissionGranted == PermissionStatus.deniedForever) {
//       return Future.error(
//         'Location permissions are permanently denied. Please enable them in settings.',
//       );
//     }

//     // Get current location
//     try {
//       final LocationData locationData = await location.getLocation();

//       return locationData;
//     } catch (e) {
//       return Future.error('Failed to get location: $e');
//     }
//   }

//   static Future<String?> getDeviceToken() async {
//     try {
//       final String? token = DeviceUtils.isAndroid()
//           ? await FirebaseMessaging.instance.getToken()
//           : await FirebaseMessaging.instance.getAPNSToken();

//       if (token != null) {
//         debugPrint('Device FCM Token: $token');

//         return token;
//       } else {
//         debugPrint('Failed to retrieve FCM token');
//       }
//     } catch (e) {
//       debugPrint('Error retrieving FCM token: $e');
//     }
//     return null;
//   }

//   static String generateRandomUsername() {
//     const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
//     final Random random = Random();
//     final String firstPart = List.generate(
//       4,
//       (index) => characters[random.nextInt(characters.length)],
//     ).join();
//     final String secondPart = List.generate(
//       3,
//       (index) => characters[random.nextInt(characters.length)],
//     ).join();
//     return '$firstPart $secondPart';
//   }

//   static DateTime getToday() {
//     return DateTime.now();
//   }

//   static double calculateDistanceFrom({
//     LatLng? userLocation,
//     String? latitude,
//     String? longitude,
//   }) {
//     if (userLocation == null) return 0.0;

//     const double earthRadius = 6371.0; // Earth's radius in km

//     final double? lat2Raw = latitude != null ? double.tryParse(latitude) : null;
//     final double? lon2Raw = longitude != null ? double.tryParse(longitude) : null;

//     // Validate coordinates (basic check for valid range and non-zero)
//     if (lat2Raw == null ||
//         lon2Raw == null ||
//         lat2Raw == 0 ||
//         lon2Raw == 0 ||
//         lat2Raw < 8 ||
//         lat2Raw > 16 ||
//         lon2Raw < 100 ||
//         lon2Raw > 110) {
//       return 0.0;
//     }

//     final double lat1 = userLocation.latitude * (pi / 180);
//     final double lon1 = userLocation.longitude * (pi / 180);
//     final double lat2 = lat2Raw * (pi / 180);
//     final double lon2 = lon2Raw * (pi / 180);

//     final double dLat = lat2 - lat1;
//     final double dLon = lon2 - lon1;
//     final double a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
//     final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

//     return double.parse((earthRadius * c).toStringAsFixed(2));
//   }

//   static bool? toBool(dynamic value) {
//     if (value == null) return null;

//     if (value is bool) return value;

//     if (value is int) {
//       if (value == 1) return true;
//       if (value == 0) return false;
//     }

//     if (value is String) {
//       final normalized = value.trim().toLowerCase();
//       if (['true', 'yes', '1', 'y', 'on'].contains(normalized)) return true;
//       if (['false', 'no', '0', 'n', 'off'].contains(normalized)) return false;
//     }

//     return null; // Could not interpret
//   }

//   static NavigatorState navigatorState(BuildContext context) {
//     return Navigator.of(context);
//   }

//   static Future<File?> pickImage(ImageSource source) async {
//     final XFile? pickedFile = await ImagePicker().pickImage(source: source);

//     if (pickedFile != null) {
//       return File(pickedFile.path);
//     }
//     return null;
//   }

//   static String getLastExtension(String filePath) {
//     final int lastDotIndex = filePath.lastIndexOf('.');
//     if (lastDotIndex != -1) {
//       return filePath.substring(lastDotIndex + 1);
//     }
//     return ''; // Return empty string if no extension found
//   }

//   static String getLastFileName(String filePath) {
//     final int lastSlashIndex = filePath.lastIndexOf('/');
//     if (lastSlashIndex != -1) {
//       return filePath.substring(lastSlashIndex);
//     }
//     return filePath;
//   }

//   static String getDownloadedFile(String url) {
//     final Uri uri = Uri.parse(url);

//     String fileName = uri.path.replaceAll('/o/', '*');
//     fileName = fileName.replaceAll('?', '*');
//     fileName = fileName.split('*')[1];
//     return fileName;
//   }

//   static String getFileExtension(String filePath) {
//     final int lastDotIndex = filePath.lastIndexOf('.');
//     if (lastDotIndex != -1) {
//       return filePath.substring(lastDotIndex + 1);
//     }
//     return '';
//   }

//   static Future<File?> cropAndCompressImage(String sourcePath) async {
//     final croppedImage = await ImageCropper().cropImage(
//       sourcePath: sourcePath,
//       compressQuality: 60,
//       uiSettings: [
//         AndroidUiSettings(
//           toolbarTitle: 'SFA Crop Image',
//           toolbarColor: AppColors.primary700,
//           toolbarWidgetColor: Colors.white,
//           activeControlsWidgetColor: AppColors.primary700,
//           lockAspectRatio: false,
//         ),
//         IOSUiSettings(title: 'SFA Crop Image'),
//       ],
//     );
//     if (croppedImage == null) {
//       return null;
//     }

//     return File(croppedImage.path);
//   }

//   static Future<void> removeSplashScreen() async {
//     await Future.delayed(const Duration(seconds: 3));
//     FlutterNativeSplash.remove();
//   }

//   static Future delay(int miliseconds, Function exce) async {
//     await Future.delayed(Duration(milliseconds: miliseconds), () {
//       exce();
//     });
//   }

//   static void showErrorSnackbar(
//     BuildContext context,
//     String title,
//     String message,
//     String locale,
//     AppTheme appTheme,
//     StatusSnackbar status, {
//     int? duration = 500,
//   }) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         duration: Duration(milliseconds: duration ?? 500),
//         content: Column(
//           children: [
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: AppTextTheme.getTextTheme(appTheme, locale).bodyLarge
//                   ?.copyWith(
//                     fontWeight: FontWeight.w500,
//                     color: status == StatusSnackbar.success
//                         ? AppColors.neutral50
//                         : AppColors.neutral50,
//                   ),
//             ),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: AppTextTheme.getTextTheme(appTheme, locale).bodyMedium
//                   ?.copyWith(
//                     fontWeight: FontWeight.w400,
//                     color: status == StatusSnackbar.success
//                         ? AppColors.neutral50
//                         : AppColors.neutral50,
//                   ),
//             ),
//           ],
//         ),
//         backgroundColor: status == StatusSnackbar.success
//             ? AppColors.primary600
//             : AppColors.red500,
//       ),
//     );
//   }

//   static Response validateResponse(Response response) {
//     final statusCode = response.statusCode;

//     if (statusCode != null) {
//       if (statusCode >= 200 && statusCode < 300) {
//         return response; // Return the response if status is in the 2xx range
//       } else {
//         // Handle specific status codes
//         switch (statusCode) {
//           case 400:
//             throw BadRequestException(
//               message: '${response.statusMessage}',
//               title: 'Bad Request',
//             );
//           case 401:
//             throw ForbiddenException(
//               message: '${response.statusMessage}',
//               title: 'Unauthorize',
//             );
//           case 403:
//             throw ForbiddenException(
//               message: '${response.statusMessage}',
//               title: 'Unauthorize',
//             );
//           case 404:
//             throw NotFoundException(
//               message: '${response.statusMessage}',
//               title: 'Not Found',
//             );
//           case 500:
//             throw InternalServerException(
//               message: '${response.statusMessage}',
//               title: 'Server is Down',
//             );
//           default:
//             throw UnknownException(
//               message: '${response.statusMessage}',
//               title: 'Oops',
//             );
//         }
//       }
//     } else {
//       throw UnknownException(
//         title: 'Oops',
//         message: 'Response does not contain a status code',
//       );
//     }
//   }

//   static Future<void> deepLinkLauncher(String url) async {
//     final Uri uri = Uri.parse(url);
//     if (!await launchUrl(uri)) {
//       throw Exception('Could not launch $url');
//     }
//   }

//   /// Generates a PDF from the invoice detail and shares it.
//   /// Shows a loading indicator while generating, then shares the PDF.
//   static Future<void> shareInvoiceAsPdf(
//     BuildContext context,
//     SaleInvoiceDetailResponse detail,
//   ) async {
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     try {
//       // Show a loading indicator
//       // ignore: unawaited_futures
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: CircularProgressIndicator()),
//       );

//       // Generate the PDF and get the file
//       final file = await PdfInvoiceGenerator.generate(detail);

//       // Hide the loading indicator
//       if (context.mounted) {
//         Navigator.of(context).pop();
//       }

//       // Create XFile with proper MIME type for better iOS compatibility
//       final xFile = XFile(
//         file.path,
//         mimeType: 'application/pdf',
//         name: 'Invoice_${detail.invoiceNo}.pdf',
//       );

//       // Share the generated file using SharePlus
//       await SharePlus.instance.share(
//         ShareParams(
//           files: [xFile],
//           text: 'Here is the invoice for ${detail.customerName}',
//           subject: 'Invoice ${detail.invoiceNo}',
//         ),
//       );
//     } catch (e) {
//       // Hide loading indicator if still showing
//       if (context.mounted) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }
//       // Show error
//       scaffoldMessenger.showSnackBar(
//         SnackBar(content: Text('Failed to generate PDF: $e')),
//       );
//     }
//   }

//   /// Generates a PDF from the order detail and shares it.
//   /// Shows a loading indicator while generating, then shares the PDF.
//   static Future<void> shareOrderAsPdf(
//     BuildContext context,
//     OrderHistoryItemModel order,
//   ) async {
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     try {
//       // Show a loading indicator
//       // ignore: unawaited_futures
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: CircularProgressIndicator()),
//       );

//       // Generate the PDF and get the file
//       final file = await PdfOrderGenerator.generate(order);

//       // Hide the loading indicator
//       if (context.mounted) {
//         Navigator.of(context).pop();
//       }

//       // Create XFile with proper MIME type for better iOS compatibility
//       final xFile = XFile(
//         file.path,
//         mimeType: 'application/pdf',
//         name: 'Order_${order.orderNo}.pdf',
//       );

//       // Share the generated file using SharePlus
//       await SharePlus.instance.share(
//         ShareParams(
//           files: [xFile],
//           text: 'Here is the order for ${order.customerName ?? order.customer}',
//           subject: 'Order ${order.orderNo}',
//         ),
//       );
//     } catch (e) {
//       // Hide loading indicator if still showing
//       if (context.mounted) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }
//       // Show error
//       scaffoldMessenger.showSnackBar(
//         SnackBar(content: Text('Failed to generate PDF: $e')),
//       );
//     }
//   }

//   static Future<List<File>?> getImageFromSource({
//     required BuildContext context,
//     required bool isCamera,
//     int maxImageCount = 1,
//     int maxImageSizeMB = 5,
//     bool useFastCompression = true,
//     String subDir = 'sfa_images',
//     VoidCallback? onImagePicked,
//     bool allowSkip = false,
//     List<CameraLensDirection>? preferredSequence,
//   }) async {
//     final ImagePicker picker = ImagePicker();
//     final List<File> imageFiles = [];

//     try {
//       if (isCamera) {
//         final List<XFile>? images = await Navigator.push<List<XFile>?>(
//           context,
//           MaterialPageRoute(
//             builder: (_) => CustomCameraScreen(
//               allowSkip: allowSkip,
//               requiredCount: maxImageCount,
//               preferredSequence: preferredSequence,
//             ),
//           ),
//         );

//         if (images != null && images.isNotEmpty) {
//           if (onImagePicked != null) {
//             onImagePicked();
//           }

//           for (final image in images) {
//             // Use getPathLocalDirectory for consistent directory access
//             final permanentDir = await getPathLocalDirectory(
//               subDirectory: subDir,
//             );

//             final permanentPath =
//                 '${permanentDir.path}/image_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}.jpg';

//             // Choose compression method based on parameter
//             final Uint8List compressedData = useFastCompression
//                 ? await _compressImageFast(File(image.path))
//                 : await _compressImageOptimized(File(image.path));

//             // Write compressed data to permanent location
//             final compressedFile = File(permanentPath);
//             await compressedFile.writeAsBytes(compressedData);

//             // Save to gallery if it's a camera image
//             try {
//               // Check and request access
//               bool hasAccess = await Gal.hasAccess();
//               if (!hasAccess) {
//                 hasAccess = await Gal.requestAccess();
//               }

//               if (hasAccess) {
//                 await Gal.putImage(permanentPath);
//               }
//             } catch (e) {
//               debugPrint('Error saving to gallery: $e');
//             }

//             imageFiles.add(compressedFile);
//           }
//         }
//       } else {
//         // NEW LOGIC: Handle single vs multiple image selection based on maxImageCount
//         if (maxImageCount == 1) {
//           // Single image selection
//           final XFile? pickedFile = await picker.pickImage(
//             source: ImageSource.gallery,
//             requestFullMetadata: false,
//           );

//           if (pickedFile != null) {
//             if (onImagePicked != null) {
//               onImagePicked();
//             }
//             // Check file size before processing
//             if (await _isFileSizeWithinLimit(pickedFile.path, maxImageSizeMB)) {
//               final processedFile = await _processSingleImageFile(
//                 pickedFile,
//                 useFastCompression,
//               );
//               if (processedFile != null) {
//                 imageFiles.add(processedFile);
//               }
//             } else {
//               _showSizeLimitWarning(context, pickedFile.name, maxImageSizeMB);
//             }
//           }
//         } else {
//           // Multiple image selection
//           final List<XFile> pickedFiles = await picker.pickMultiImage(
//             requestFullMetadata: false,
//           );

//           if (pickedFiles.isNotEmpty) {
//             if (onImagePicked != null) {
//               onImagePicked();
//             }
//             // Apply maxImageCount limit
//             final filesToProcess = pickedFiles.length > maxImageCount
//                 ? pickedFiles.sublist(0, maxImageCount)
//                 : pickedFiles;

//             // Show warning if some images were excluded due to limit
//             if (pickedFiles.length > maxImageCount) {
//               _showImageLimitWarning(
//                 context,
//                 pickedFiles.length,
//                 maxImageCount,
//               );
//             }

//             // Process each image
//             for (final pickedFile in filesToProcess) {
//               // Check file size before processing
//               if (await _isFileSizeWithinLimit(
//                 pickedFile.path,
//                 maxImageSizeMB,
//               )) {
//                 final processedFile = await _processSingleImageFile(
//                   pickedFile,
//                   useFastCompression,
//                 );
//                 if (processedFile != null) {
//                   imageFiles.add(processedFile);
//                 }
//               } else {
//                 _showSizeLimitWarning(context, pickedFile.name, maxImageSizeMB);
//               }
//             }
//           }
//         }
//       }

//       if (imageFiles.isEmpty) {
//         debugPrint('No images selected');
//         return null;
//       }

//       return imageFiles;
//     } catch (e, stackTrace) {
//       debugPrint('Error processing images: $e\n$stackTrace');
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error processing image: ${e.toString()}')),
//         );
//       }
//       return null;
//     }
//   }

//   // NEW HELPER METHOD: Check if file size is within limit
//   static Future<bool> _isFileSizeWithinLimit(
//     String filePath,
//     int maxSizeMB,
//   ) async {
//     try {
//       final file = File(filePath);
//       final fileSize = await file.length();
//       final maxSizeBytes = maxSizeMB * 1024 * 1024;
//       return fileSize <= maxSizeBytes;
//     } catch (e) {
//       debugPrint('Error checking file size: $e');
//       return false;
//     }
//   }

//   // NEW HELPER METHOD: Process single image file
//   static Future<File?> _processSingleImageFile(
//     XFile pickedFile,
//     bool useFastCompression,
//   ) async {
//     try {
//       // Use getPathLocalDirectory for consistent directory access
//       final permanentDir = await getPathLocalDirectory(
//         subDirectory: 'sfa_images',
//       );

//       // Choose compression method
//       final Uint8List compressedData = useFastCompression
//           ? await _compressImageFast(File(pickedFile.path))
//           : await _compressImageOptimized(File(pickedFile.path));

//       final permanentPath =
//           '${permanentDir.path}/image_${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
//       final compressedFile = File(permanentPath);
//       await compressedFile.writeAsBytes(compressedData);

//       debugPrint('Compressed gallery image saved to: $permanentPath');
//       return compressedFile;
//     } catch (e) {
//       debugPrint('Error processing image ${pickedFile.name}: $e');
//       return null;
//     }
//   }

//   // NEW HELPER METHOD: Show image limit warning
//   static void _showImageLimitWarning(
//     BuildContext context,
//     int selectedCount,
//     int maxCount,
//   ) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Limited to $maxCount images. Selected $selectedCount.',
//           ),
//           backgroundColor: AppColors.yellow600,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   // NEW HELPER METHOD: Show file size limit warning
//   static void _showSizeLimitWarning(
//     BuildContext context,
//     String fileName,
//     int maxSizeMB,
//   ) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             '$fileName is too large. Maximum allowed: $maxSizeMB MB.',
//           ),
//           backgroundColor: Colors.orange,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   /// Optimized image compression for faster processing using native compressor
//   static Future<Uint8List> _compressImageOptimized(File file) async {
//     if (!await file.exists()) {
//       throw Exception('File does not exist: ${file.path}');
//     }

//     const int targetSize = 300 * 1024; // 300KB
//     const int minQuality = 50;
//     const int stepQuality = 15;

//     try {
//       final int fileSize = await file.length();

//       // If image is already smaller than target, return as is
//       if (fileSize <= targetSize) {
//         debugPrint('Image already under target size: $fileSize bytes');
//         return await file.readAsBytes();
//       }

//       int quality = 85;
//       if (fileSize > 5 * 1024 * 1024) {
//         quality = 60;
//       } else if (fileSize > 2 * 1024 * 1024) {
//         quality = 70;
//       } else if (fileSize > 1 * 1024 * 1024) {
//         quality = 75;
//       }

//       var result = await FlutterImageCompress.compressWithFile(
//         file.absolute.path,
//         minWidth: 1200,
//         minHeight: 1200,
//         quality: quality,
//       );

//       // Recursive compression if still too large
//       if (result != null && result.length > targetSize) {
//         debugPrint(
//           'First compression: ${result.length} bytes, trying lower quality',
//         );

//         // Try lower quality
//         int nextQuality = quality - stepQuality;
//         if (nextQuality < minQuality) nextQuality = minQuality;

//         result = await FlutterImageCompress.compressWithFile(
//           file.absolute.path,
//           minWidth: 1200,
//           minHeight: 1200,
//           quality: nextQuality,
//         );

//         // If still too large, resize more aggressively
//         if (result != null && result.length > targetSize) {
//           debugPrint(
//             'Second compression still too large: ${result.length} bytes',
//           );
//           result = await FlutterImageCompress.compressWithFile(
//             file.absolute.path,
//             minWidth: 800,
//             minHeight: 800,
//             quality: 50,
//           );
//         }
//       }

//       if (result == null) {
//         throw Exception('Native compression failed');
//       }

//       debugPrint('Compression successful: ${result.length} bytes');
//       return result;
//     } catch (e) {
//       debugPrint('Native compression failed, falling back: $e');
//       return await file.readAsBytes();
//     }
//   }

//   /// Alternative: Simple and fast compression for very quick processing
//   static Future<Uint8List> _compressImageFast(File file) async {
//     if (!await file.exists()) {
//       throw Exception('File does not exist: ${file.path}');
//     }

//     const int targetSize = 300 * 1024; // 300KB

//     try {
//       final int fileSize = await file.length();

//       // If image is already small enough, return as is
//       if (fileSize <= targetSize) {
//         return await file.readAsBytes();
//       }

//       // Single pass fast compression
//       final result = await FlutterImageCompress.compressWithFile(
//         file.absolute.path,
//         minWidth: 800, // Reduced from 1000 for low RAM pos devices
//         minHeight: 800,
//         quality: 60, // Reduced from 70 to save memory and processing time
//       );

//       if (result == null) {
//         return await file.readAsBytes();
//       }

//       debugPrint('Fast compression: $fileSize -> ${result.length} bytes');
//       return result;
//     } catch (e) {
//       debugPrint('Fast compression failed: $e');
//       return await file.readAsBytes();
//     }
//   }

//   /// Deletes a single file from local storage
//   static Future<bool> deleteFile(String? filePath) async {
//     if (filePath == null || filePath.isEmpty) {
//       debugPrint('No file path provided for deletion');
//       return false;
//     }

//     try {
//       final file = File(filePath);

//       if (await file.exists()) {
//         await file.delete();
//         debugPrint('File deleted successfully: $filePath');
//         return true;
//       } else {
//         debugPrint('File does not exist: $filePath');
//         return false;
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error deleting file: $e\n$stackTrace');
//       return false;
//     }
//   }

//   /// Deletes multiple files from local storage
//   static Future<void> deleteFiles(List<String> filePaths) async {
//     for (final filePath in filePaths) {
//       await deleteFile(filePath);
//     }
//   }

//   /// Clears all images from the SFA images directory
//   static Future<void> clearAllSfaImages() async {
//     try {
//       final sfaImagesDir = await getPathLocalDirectory(
//         subDirectory: 'sfa_images',
//       );

//       if (await sfaImagesDir.exists()) {
//         await sfaImagesDir.delete(recursive: true);
//         debugPrint('All SFA images cleared successfully');
//       } else {
//         debugPrint('SFA images directory does not exist');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error clearing SFA images: $e\n$stackTrace');
//     }
//   }

//   /// Gets the SFA images directory path
//   static Future<String> getSfaImagesDirectoryPath() async {
//     final sfaImagesDir = await getPathLocalDirectory(
//       subDirectory: 'sfa_images',
//     );
//     return sfaImagesDir.path;
//   }

//   /// Checks if a file exists in local storage
//   static Future<bool> fileExists(String? filePath) async {
//     if (filePath == null || filePath.isEmpty) {
//       return false;
//     }

//     try {
//       final file = File(filePath);
//       return await file.exists();
//     } catch (e) {
//       debugPrint('Error checking file existence: $e');
//       return false;
//     }
//   }

//   /// Gets file size in bytes
//   static Future<int?> getFileSize(String? filePath) async {
//     if (filePath == null || filePath.isEmpty) {
//       return null;
//     }

//     try {
//       final file = File(filePath);
//       if (await file.exists()) {
//         return await file.length();
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Error getting file size: $e');
//       return null;
//     }
//   }

//   /// Gets file size in human readable format (KB, MB, etc.)
//   static Future<String?> getFileSizeReadable(String? filePath) async {
//     final sizeInBytes = await getFileSize(filePath);
//     if (sizeInBytes == null) return null;

//     if (sizeInBytes < 1024) {
//       return '$sizeInBytes B';
//     } else if (sizeInBytes < 1048576) {
//       return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
//     } else {
//       return '${(sizeInBytes / 1048576).toStringAsFixed(1)} MB';
//     }
//   }

//   static Response? handleApiResponse(Response response) {
//     switch (response.statusCode) {
//       case 200:
//         return response;
//       case 304:
//         // Throw error ehre
//         break;
//       case 400:
//         // Throw error ehre
//         break;
//       case 401:
//         // Throw error ehre
//         break;
//       case 403:
//         // Throw error ehre
//         break;
//       case 404:
//         // Throw error ehre
//         break;
//       case 500:
//         // Throw error ehre
//         break;
//       default:
//         break;
//     }
//     return null;
//   }

//   static void printLong(String text) {
//     // Split into chunks of 800 characters to avoid truncation in some terminals
//     const int chunkSize = 800;
//     for (int i = 0; i < text.length; i += chunkSize) {
//       final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
//       // ignore: avoid_print
//       print(text.substring(i, end));
//     }
//   }

//   /// Gets the appropriate directory for saving files.
//   /// Uses application documents directory (safe, private, works on iOS & Android).
//   static Future<Directory> getPathLocalDirectory({String? subDirectory}) async {
//     final baseDir = await getApplicationDocumentsDirectory();

//     if (subDirectory != null) {
//       final dir = Directory('${baseDir.path}/$subDirectory');
//       if (!await dir.exists()) {
//         await dir.create(recursive: true);
//       }
//       return dir;
//     }

//     return baseDir;
//   }
// }

// class Tuple<T, R> {
//   final T item1;
//   final R item2;
//   Tuple({required this.item1, required this.item2});
// }

// class PageTuple<T, R> {
//   final T start;
//   final R end;
//   PageTuple({required this.start, required this.end});
// }

// PageTuple<int, int> getStartEnd({
//   required PageRequest pageRequest,
//   required int totalRecords,
// }) {
//   final start = pageRequest.page * pageRequest.size;
//   final total = start + pageRequest.size;
//   final end = start == 0 && totalRecords <= pageRequest.size
//       ? totalRecords
//       : start == 0
//       ? pageRequest.size
//       : total >= totalRecords
//       ? totalRecords
//       : start + pageRequest.size;
//   return PageTuple(start: start, end: end);
// }

// sealed class ResponseEnum {
//   final String _name;
//   const ResponseEnum({required String name}) : _name = name;

//   @override
//   String toString() => _name;
// }

// class SaleItemOriginEnum extends ResponseEnum {
//   const SaleItemOriginEnum({required super.name});

//   static const SaleItemOriginEnum std = SaleItemOriginEnum(name: 'STD');
//   static const SaleItemOriginEnum tdo = SaleItemOriginEnum(name: 'TDO');
//   static const SaleItemOriginEnum tdp = SaleItemOriginEnum(name: 'TDP');
//   static const SaleItemOriginEnum foc = SaleItemOriginEnum(name: 'FOC');
//   static const SaleItemOriginEnum tdl = SaleItemOriginEnum(name: 'TDL');
//   static const SaleItemOriginEnum tra = SaleItemOriginEnum(name: 'TRA');
//   // static const SaleItemOriginEnum tpo = SaleItemOriginEnum(name: 'TPO');
//   // static const SaleItemOriginEnum tdi = SaleItemOriginEnum(name: 'TDI');

//   static List<SaleItemOriginEnum> get values => [std, tdo, foc, tdl, tra, tdp];

//   /// All types except STD (for reward/promotion quantity handling)
//   static List<SaleItemOriginEnum> get rewardValues => [tdo, foc, tdl, tra, tdp];
// }

// typedef ProgressCallback =
//     void Function(double progress, int current, int total);
// typedef ReturnCallBack<T> = T Function();

// String getTypeNameForEnum(OutletTypes type) {
//   switch (type) {
//     case OutletTypes.Direct:
//       return 'Direct';
//     case OutletTypes.Indirect:
//       return 'Indirect';
//     case OutletTypes.DirectMC:
//       return 'Direct MC';
//     case OutletTypes.All:
//       return '';
//   }
// }

// class VisitStatusConst {
//   static const String active = 'Active';
//   static const String checkedIn = 'Checked-In';
//   static const String checkedOut = 'Checked-Out';
//   static const String approved = 'Approved';
//   static const String unplanned = 'Unplanned';
// }

// class ProductCategory {
//   static const String all = 'All';
//   static const String meechiet = 'Mee Chiet';
//   static const String vital = 'Vital';
//   static const String omk = 'OMK';
//   static const String water = 'Water';
//   static const String noodle = 'Noodle';
// }

// class PORequestStatus {
//   static const String pending = 'Pending';
//   static const String received = 'Received';
//   static const String rejected = 'Rejected';
// }

// class SaleInvoiceStatus {
//   static const String paid = 'Paid';
//   static const String partiallySettled = 'Partially Settled';
//   static const String settled = 'Settled';
//   static const String closed = 'Closed';
//   static const String canceled = 'Canceled';
// }

// class SaleOrderStatus {
//   static const String pending = 'Pending';
//   static const String posted = 'Posted';
//   static const String received = 'Received';
//   static const String rejected = 'Rejected';
//   static const String canceled = 'Canceled';
//   static const String delivered = 'Delivered';
//   static const String completed = 'Completed';
//   static const String paid = 'Paid';
// }

// /// Task Sync Upload statuses from backend (service.py and sync.py)
// /// - uploaded    : Initial upload complete
// /// - inProgress  : Syncing tasks to server
// /// - completed   : All tasks synced successfully
// /// - failed      : Error occurred during sync
// /// - pending     : Individual task pending status
// class TaskSyncStatus {
//   static const String uploaded = 'Uploaded';
//   static const String inProgress = 'In Progress';
//   static const String completed = 'Completed';
//   static const String failed = 'Failed';
//   static const String pending = 'Pending';
//   static const String canceled = 'Canceled';

//   /// Check if status indicates success
//   static bool isSuccess(String? status) {
//     final s = status?.toLowerCase() ?? '';
//     return s == 'completed';
//   }

//   /// Check if status indicates failure
//   static bool isFailed(String? status) {
//     return status?.toLowerCase() == 'failed';
//   }

//   /// Check if status indicates in progress
//   static bool isInProgress(String? status) {
//     return status?.toLowerCase() == 'in progress';
//   }

//   /// Check if status indicates uploaded/pending
//   static bool isUploaded(String? status) {
//     return status?.toLowerCase() == 'uploaded';
//   }

//   /// Check if status indicates pending
//   static bool isPending(String? status) {
//     return status?.toLowerCase() == 'pending';
//   }

//   /// Check if status indicates canceled
//   static bool isCanceled(String? status) {
//     return status?.toLowerCase() == 'canceled';
//   }
// }

// class DocumentType {
//   static const String saleOrder = 'Sale Order';
//   static const String saleInvoice = 'Sale Invoice';
// }

// class Currency {
//   static const String usd = 'USD';
//   static const String khr = 'KHR';
// }

// class ExchangeRate {
//   static const String usd = '1';
//   static const String khr = '4000';
// }

// class ShippingStatus {
//   static const String pending = 'Pending';
//   static const String received = 'Delivered';
//   static const String rejected = 'Rejected';
// }

// class CallPlanType {
//   static const String visit = 'Visit';
//   static const String unplannedVisit = 'Unplanned Visit';
// }

// String normalizeStatus(String? rawStatus) {
//   if (rawStatus == null) return VisitStatusConst.approved;
//   final s = rawStatus.trim().toLowerCase();

//   if (s.contains('checked-in') || s == 'checked in') {
//     return VisitStatusConst.checkedIn;
//   }
//   if (s.contains('checked-out') || s == 'checked out') {
//     return VisitStatusConst.checkedOut;
//   }
//   if (s.contains('unplanned')) return VisitStatusConst.unplanned;
//   if (s.contains('approved')) return VisitStatusConst.approved;

//   return VisitStatusConst.approved;
// }

// Map<String, ApiVisitStatus> mapVisitsToApiStatuses(List<VisitModel> visits) {
//   return {
//     for (final visit in visits)
//       visit.id.toString(): parseApiVisitStatus(visit.status),
//   };
// }

// ApiVisitStatus parseApiVisitStatus(dynamic status) {
//   if (status is ApiVisitStatus) return status;
//   if (status is String) {
//     switch (normalizeStatus(status)) {
//       case VisitStatusConst.approved:
//         return ApiVisitStatus.Approved;
//       case VisitStatusConst.checkedIn:
//         return ApiVisitStatus.CheckedIn;
//       case VisitStatusConst.checkedOut:
//         return ApiVisitStatus.CheckedOut;
//       case VisitStatusConst.unplanned:
//         return ApiVisitStatus.Unplanned;
//     }
//   }
//   return ApiVisitStatus.Approved;
// }

// Map<String, VisitStatus> mapApiStatusesToUiStatuses(
//   Map<String, ApiVisitStatus> apiStatuses,
// ) {
//   return apiStatuses.map((id, status) {
//     switch (status) {
//       case ApiVisitStatus.Approved:
//         return MapEntry(id, VisitStatus.NotStarted);
//       case ApiVisitStatus.CheckedIn:
//         return MapEntry(id, VisitStatus.InProgress);
//       case ApiVisitStatus.CheckedOut:
//         return MapEntry(id, VisitStatus.Completed);
//       case ApiVisitStatus.Unplanned:
//         return MapEntry(id, VisitStatus.Unplanned);
//     }
//   });
// }

// class MissionStatusConst {
//   static const String all = 'All';
//   static const String pending = 'Pending';
//   static const String active = 'Active';
//   static const String inProgress = 'In Progress';
//   static const String completed = 'Completed';

//   static const String pendingApi = 'pending';
//   static const String activeApi = 'active';
//   static const String inProgressApi = 'in_progress';
//   static const String completedApi = 'completed';

//   static bool isOnlyActive(String? status) {
//     if (status == null) return false;
//     final s = status.trim().toLowerCase();
//     return s == 'active' || s == 'pending';
//   }

//   /// Check if status represents exactly an in-progress mission.
//   static bool isInProgress(String? status) {
//     if (status == null) return false;
//     final s = status.trim().toLowerCase();
//     return s == 'in progress' || s == 'in_progress';
//   }

//   /// Check if status represents an active or in-progress mission.
//   static bool isNotCompleted(String? status) {
//     return isOnlyActive(status) || isInProgress(status);
//   }

//   /// Check if status represents a completed mission.
//   static bool isCompleted(String? status) {
//     if (status == null) return false;
//     final s = status.trim().toLowerCase();
//     return s == 'completed';
//   }

//   static final List<Map<String, String>> filterOptions = [
//     {'label': all, 'value': all, 'apiValue': ''},
//     {'label': active, 'value': active, 'apiValue': activeApi},
//     {'label': inProgress, 'value': inProgress, 'apiValue': inProgressApi},
//     {'label': completed, 'value': completed, 'apiValue': completedApi},
//   ];
// }

// class MissionDateFilterConst {
//   static const String all = 'All';
//   static const String today = 'Today';
//   static const String thisWeek = 'This Week';
//   static const String thisMonth = 'This Month';

//   static const String todayValue = 'Today';
//   static const String thisWeekValue = 'This_Week';
//   static const String thisMonthValue = 'This_Month';

//   static const String todayApi = 'today';
//   static const String thisWeekApi = 'this_week';
//   static const String thisMonthApi = 'this_month';

//   static final List<Map<String, String>> filterOptions = [
//     {'label': all, 'value': all, 'apiValue': ''},
//     {'label': today, 'value': todayValue, 'apiValue': todayApi},
//     {'label': thisWeek, 'value': thisWeekValue, 'apiValue': thisWeekApi},
//     {'label': thisMonth, 'value': thisMonthValue, 'apiValue': thisMonthApi},
//   ];
}
