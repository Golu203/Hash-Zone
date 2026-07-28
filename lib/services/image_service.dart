import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads image file bytes to Cloudinary if credentials are configured,
  /// otherwise uploads directly to Firebase Storage.
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'hashzone_products',
    String cloudinaryCloudName = '',
    String cloudinaryUploadPreset = '',
  }) async {
    // 1. Try Cloudinary if cloud name & preset are available
    if (cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
        );
        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = cloudinaryUploadPreset
          ..fields['folder'] = folder
          ..files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
          ));

        final response = await request.send();
        if (response.statusCode == 200) {
          final resData = await response.stream.bytesToString();
          final json = jsonDecode(resData);
          if (json['secure_url'] != null) {
            return json['secure_url'] as String;
          }
        }
      } catch (e) {
        // Fallback to Firebase storage on error
      }
    }

    // 2. Firebase Storage fallback
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$folder/${timestamp}_$filename';
    final ref = _storage.ref().child(path);
    
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await uploadTask.ref.getDownloadURL();
  }
}
