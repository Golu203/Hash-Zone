import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/cloudinary_image.dart';

class CloudinaryService {
  /// Uploads raw image bytes directly to Cloudinary using unsigned REST upload with progress tracking.
  Future<CloudinaryImage> uploadImage({
    required Uint8List bytes,
    required String filename,
    required String cloudName,
    required String uploadPreset,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    final effectiveCloudName = cloudName.isNotEmpty ? cloudName : 'um227ll2';
    final effectivePreset = uploadPreset.isNotEmpty ? uploadPreset : 'hashzone_products';
    final effectiveFolder = folder.isNotEmpty ? folder : 'hashzone/products';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$effectiveCloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = effectivePreset
      ..fields['folder'] = effectiveFolder
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));

    final totalBytes = request.contentLength;
    onProgress?.call(0.1); // Initializing upload

    final streamedResponse = await request.send();

    final responseBytes = <int>[];
    int uploadedBytes = 0;

    final completer = Completer<http.Response>();

    streamedResponse.stream.listen(
      (chunk) {
        responseBytes.addAll(chunk);
        uploadedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (uploadedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress?.call(progress);
        }
      },
      onDone: () {
        completer.complete(http.Response.bytes(responseBytes, streamedResponse.statusCode));
      },
      onError: (error) {
        completer.completeError(error);
      },
      cancelOnError: true,
    );

    final response = await completer.future;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      onProgress?.call(1.0); // 100% complete

      return CloudinaryImage(
        url: data['secure_url'] ?? '',
        publicId: data['public_id'] ?? '',
        width: (data['width'] ?? 0) is int ? data['width'] : int.tryParse(data['width'].toString()) ?? 0,
        height: (data['height'] ?? 0) is int ? data['height'] : int.tryParse(data['height'].toString()) ?? 0,
        format: data['format'] ?? 'jpg',
        isCover: false,
        displayOrder: 1,
      );
    } else {
      onProgress?.call(0.0);
      throw Exception('Cloudinary upload failed [Status ${response.statusCode}]: ${response.body}');
    }
  }

  /// Triggers a secure serverless deletion request via Vercel backend using the image's publicId.
  Future<bool> deleteImage(String publicId) async {
    if (publicId.isEmpty) return false;
    
    try {
      // Use relative URL for Vercel Web deployment
      final uri = Uri.parse('/api/delete-image');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'public_id': publicId}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] == 'ok';
      } else {
        print('Cloudinary deletion failed [Status ${response.statusCode}]: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error calling Cloudinary deletion API: $e');
      return false;
    }
  }

  /// Extracts the Cloudinary publicId from a secure URL.
  String? extractPublicId(String url) {
    if (!url.contains('res.cloudinary.com')) return null;
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final uploadIdx = pathSegments.indexOf('upload');
      if (uploadIdx == -1 || uploadIdx >= pathSegments.length - 1) return null;
      
      var startIndex = uploadIdx + 1;
      // Skip the version segment (e.g. v17218392)
      if (startIndex < pathSegments.length &&
          pathSegments[startIndex].startsWith('v') &&
          RegExp(r'^v\d+$').hasMatch(pathSegments[startIndex])) {
        startIndex += 1;
      }
      
      final segments = pathSegments.sublist(startIndex);
      final fullPublicIdWithExt = segments.join('/');
      final dotIdx = fullPublicIdWithExt.lastIndexOf('.');
      if (dotIdx == -1) return fullPublicIdWithExt;
      return fullPublicIdWithExt.substring(0, dotIdx);
    } catch (e) {
      return null;
    }
  }
}
