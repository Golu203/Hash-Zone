import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/department.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/hero_banner.dart';
import '../services/firestore_service.dart';
import '../services/image_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final ImageService _imageService;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
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
    await _firestoreService.saveProduct(product);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _firestoreService.deleteProduct(id);
    notifyListeners();
  }

  Future<void> toggleProductFeatured(Product product) async {
    final updated = Product(
      id: product.id,
      title: product.title,
      sku: product.sku,
      departmentId: product.departmentId,
      categoryId: product.categoryId,
      subcategoryId: product.subcategoryId,
      price: product.price,
      images: product.images,
      description: product.description,
      specifications: product.specifications,
      isFeatured: !product.isFeatured,
      isOffer: product.isOffer,
      tags: product.tags,
      availableSizes: product.availableSizes,
      createdAt: product.createdAt,
    );
    await _firestoreService.saveProduct(updated);
  }

  Future<void> toggleProductOffer(Product product) async {
    final updated = Product(
      id: product.id,
      title: product.title,
      sku: product.sku,
      departmentId: product.departmentId,
      categoryId: product.categoryId,
      subcategoryId: product.subcategoryId,
      price: product.price,
      images: product.images,
      description: product.description,
      specifications: product.specifications,
      isFeatured: product.isFeatured,
      isOffer: !product.isOffer,
      tags: product.tags,
      availableSizes: product.availableSizes,
      createdAt: product.createdAt,
    );
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
    await _firestoreService.saveHeroBanner(banner);
  }

  Future<void> deleteHeroBanner(String id) async {
    await _firestoreService.deleteHeroBanner(id);
  }
}
