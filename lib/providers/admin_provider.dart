import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/department.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/hero_banner.dart';
import '../services/firestore_service.dart';
import '../services/image_service.dart';
import '../services/cloudinary_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final ImageService _imageService;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  bool _isUploading = false;
  final double _uploadProgress = 0.0;
  String _uploadStatusText = '';

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatusText => _uploadStatusText;

  AdminProvider(this._firestoreService, this._imageService);

  // Upload byte file
  Future<String> uploadImageBytes(
    Uint8List bytes,
    String filename, {
    String cloudinaryCloudName = '',
    String cloudinaryUploadPreset = '',
  }) async {
    _isUploading = true;
    _uploadStatusText = 'Uploading image...';
    notifyListeners();

    try {
      final url = await _imageService.uploadImageBytes(
        bytes: bytes,
        filename: filename,
        cloudinaryCloudName: cloudinaryCloudName,
        cloudinaryUploadPreset: cloudinaryUploadPreset,
      );
      _isUploading = false;
      _uploadStatusText = 'Upload successful!';
      notifyListeners();
      return url;
    } catch (e) {
      _isUploading = false;
      _uploadStatusText = 'Upload failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Product Actions
  Future<void> saveProduct(Product product) async {
    if (product.id.isNotEmpty) {
      try {
        final oldProduct = await _firestoreService.getProductById(product.id);
        if (oldProduct != null) {
          final oldPublicIds = oldProduct.images.map((img) => img.publicId).where((id) => id.isNotEmpty).toSet();
          final newPublicIds = product.images.map((img) => img.publicId).where((id) => id.isNotEmpty).toSet();
          
          final removedIds = oldPublicIds.difference(newPublicIds);
          for (final publicId in removedIds) {
            await _cloudinaryService.deleteImage(publicId);
          }
        }
      } catch (e) {
        debugPrint('Error cleaning up deleted images during product save: $e');
      }
    }
    await _firestoreService.saveProduct(product);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    try {
      final product = await _firestoreService.getProductById(id);
      if (product != null) {
        for (final img in product.images) {
          if (img.publicId.isNotEmpty) {
            await _cloudinaryService.deleteImage(img.publicId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up images during product deletion: $e');
    }
    await _firestoreService.deleteProduct(id);
    notifyListeners();
  }

  Future<void> toggleProductFeatured(Product product) async {
    final updated = product.copyWith(isFeatured: !product.isFeatured);
    await _firestoreService.saveProduct(updated);
  }

  Future<void> toggleProductOffer(Product product) async {
    final updated = product.copyWith(isOffer: !product.isOffer);
    await _firestoreService.saveProduct(updated);
  }

  // Taxonomy Actions
  Future<void> saveDepartment(Department dept) async {
    await _firestoreService.saveDepartment(dept);
  }

  Future<void> deleteDepartment(String id) async {
    await _firestoreService.deleteDepartment(id);
  }

  Future<void> saveCategory(CategoryItem category) async {
    await _firestoreService.saveCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _firestoreService.deleteCategory(id);
  }

  Future<void> saveSubcategory(Subcategory subcategory) async {
    await _firestoreService.saveSubcategory(subcategory);
  }

  Future<void> deleteSubcategory(String id) async {
    await _firestoreService.deleteSubcategory(id);
  }

  // Banner Actions
  Future<void> saveHeroBanner(HeroBannerItem banner) async {
    if (banner.id.isNotEmpty) {
      try {
        final oldBanners = await _firestoreService.streamHeroBanners().first;
        final oldBanner = oldBanners.firstWhere((b) => b.id == banner.id);
        if (oldBanner.imageUrl != banner.imageUrl) {
          final oldPublicId = _cloudinaryService.extractPublicId(oldBanner.imageUrl);
          if (oldPublicId != null) {
            await _cloudinaryService.deleteImage(oldPublicId);
          }
        }
      } catch (e) {
        debugPrint('Error cleaning up banner image on save: $e');
      }
    }
    await _firestoreService.saveHeroBanner(banner);
  }

  Future<void> deleteHeroBanner(String id) async {
    try {
      final oldBanners = await _firestoreService.streamHeroBanners().first;
      final oldBanner = oldBanners.firstWhere((b) => b.id == id);
      final oldPublicId = _cloudinaryService.extractPublicId(oldBanner.imageUrl);
      if (oldPublicId != null) {
        await _cloudinaryService.deleteImage(oldPublicId);
      }
    } catch (e) {
      debugPrint('Error cleaning up banner image on delete: $e');
    }
    await _firestoreService.deleteHeroBanner(id);
  }
}
