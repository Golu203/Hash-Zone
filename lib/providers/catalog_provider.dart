import 'dart:async';
import 'package:flutter/material.dart';
import '../models/department.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/product.dart';
import '../models/hero_banner.dart';
import '../services/firestore_service.dart';

enum SortOption { latest, priceLowToHigh, priceHighToLow }

class CatalogProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<Department> _departments = [];
  List<CategoryItem> _categories = [];
  List<Subcategory> _subcategories = [];
  List<Product> _products = [];
  List<HeroBannerItem> _heroBanners = [];

  bool _isLoading = true;
  String _selectedDepartmentId = '';
  String _selectedCategoryId = '';
  String _selectedSubcategoryId = '';
  String _selectedSizeFilter = '';
  String _searchQuery = '';
  SortOption _sortOption = SortOption.latest;
  bool _onlyOffers = false;

  StreamSubscription? _deptSub;
  StreamSubscription? _catSub;
  StreamSubscription? _subCatSub;
  StreamSubscription? _prodSub;
  StreamSubscription? _bannerSub;

  List<Department> get departments => _departments;
  List<CategoryItem> get categories => _categories;
  List<Subcategory> get subcategories => _subcategories;
  List<Product> get products => _products;
  List<HeroBannerItem> get heroBanners => _heroBanners.where((b) => b.isActive).toList();
  bool get isLoading => _isLoading;

  String get selectedDepartmentId => _selectedDepartmentId;
  String get selectedCategoryId => _selectedCategoryId;
  String get selectedSubcategoryId => _selectedSubcategoryId;
  String get selectedSizeFilter => _selectedSizeFilter;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  bool get onlyOffers => _onlyOffers;

  CatalogProvider(this._firestoreService) {
    _init();
  }

  Future<void> _init() async {
    await _firestoreService.seedDefaultDataIfEmpty();

    _deptSub = _firestoreService.streamDepartments().listen((list) {
      _departments = list;
      notifyListeners();
    });

    _catSub = _firestoreService.streamCategories().listen((list) {
      _categories = list;
      notifyListeners();
    });

    _subCatSub = _firestoreService.streamSubcategories().listen((list) {
      _subcategories = list;
      notifyListeners();
    });

    _bannerSub = _firestoreService.streamHeroBanners().listen((list) {
      _heroBanners = list;
      notifyListeners();
    });

    _prodSub = _firestoreService.streamProducts().listen((list) {
      _products = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Filter setters
  void setDepartmentFilter(String deptId) {
    _selectedDepartmentId = deptId;
    _selectedCategoryId = '';
    _selectedSubcategoryId = '';
    notifyListeners();
  }

  void setCategoryFilter(String catId) {
    _selectedCategoryId = catId;
    _selectedSubcategoryId = '';
    notifyListeners();
  }

  void setSubcategoryFilter(String subCatId) {
    _selectedSubcategoryId = subCatId;
    notifyListeners();
  }

  void setSizeFilter(String size) {
    _selectedSizeFilter = size;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleOffersOnly(bool val) {
    _onlyOffers = val;
    notifyListeners();
  }

  void clearFilters() {
    _selectedDepartmentId = '';
    _selectedCategoryId = '';
    _selectedSubcategoryId = '';
    _selectedSizeFilter = '';
    _searchQuery = '';
    _onlyOffers = false;
    _sortOption = SortOption.latest;
    notifyListeners();
  }

  // Derived filtered products list
  List<Product> get filteredProducts {
    var result = List<Product>.from(_products);

    if (_selectedDepartmentId.isNotEmpty) {
      result = result.where((p) => p.departmentId == _selectedDepartmentId).toList();
    }
    if (_selectedCategoryId.isNotEmpty) {
      result = result.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_selectedSubcategoryId.isNotEmpty) {
      result = result.where((p) => p.subcategoryId == _selectedSubcategoryId).toList();
    }
    if (_selectedSizeFilter.isNotEmpty) {
      result = result.where((p) => p.availableSizes.contains(_selectedSizeFilter)).toList();
    }
    if (_onlyOffers) {
      result = result.where((p) => p.isOffer).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        p.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }

    switch (_sortOption) {
      case SortOption.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.latest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }

  /// Get all unique sizes available across the currently filtered department/catalog
  List<String> get allAvailableSizes {
    final sizesSet = <String>{
      'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', 'Free Size',
      '16', '18', '20', '22', '24', '26', '28', '30', '32', '34', '36', '38', '40', '42', '44', '46',
      '48', '50', '52', '54', '56', '58', '60', '62', '64', '66'
    };
    final targetList = _selectedDepartmentId.isNotEmpty
        ? _products.where((p) => p.departmentId == _selectedDepartmentId)
        : _products;

    for (final p in targetList) {
      sizesSet.addAll(p.availableSizes);
    }
    
    final list = sizesSet.toList();
    // Sort standard clothing sizes in logical order XS, S, M, L, XL... then numeric 16, 18, 20...
    const standardOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', 'Free Size'];
    list.sort((a, b) {
      final indexA = standardOrder.indexOf(a);
      final indexB = standardOrder.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;

      // Handle numeric sizes sorting
      final numA = int.tryParse(a);
      final numB = int.tryParse(b);
      if (numA != null && numB != null) return numA.compareTo(numB);

      return a.compareTo(b);
    });
    return list;
  }

  List<Product> get featuredProducts {
    return _products.where((p) => p.isFeatured).toList();
  }

  List<Product> get offerProducts {
    return _products.where((p) => p.isOffer).toList();
  }

  Department? getDepartmentById(String id) {
    try {
      return _departments.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryItem? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CategoryItem> getCategoriesForDepartment(String deptId) {
    return _categories.where((c) => c.departmentId == deptId).toList();
  }

  List<Subcategory> getSubcategoriesForCategory(String catId) {
    return _subcategories.where((s) => s.categoryId == catId).toList();
  }

  @override
  void dispose() {
    _deptSub?.cancel();
    _catSub?.cancel();
    _subCatSub?.cancel();
    _prodSub?.cancel();
    _bannerSub?.cancel();
    super.dispose();
  }
}
