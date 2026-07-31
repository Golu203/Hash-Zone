import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/department.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/product.dart';
import '../models/hero_banner.dart';
import '../models/business_settings.dart';
import '../models/cloudinary_image.dart';
import '../models/supply_state.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Streams
  Stream<List<Department>> streamDepartments() {
    return _db
        .collection('departments')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Department.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<CategoryItem>> streamCategories() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryItem.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Subcategory>> streamSubcategories() {
    return _db
        .collection('subcategories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subcategory.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Product>> streamProducts() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<HeroBannerItem>> streamHeroBanners() {
    return _db
        .collection('hero_banners')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HeroBannerItem.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<BusinessSettings> streamBusinessSettings() {
    return _db
        .collection('settings')
        .doc('business')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return BusinessSettings.fromMap(doc.data()!);
      }
      return BusinessSettings();
    });
  }

  // Get Single Product
  Future<Product?> getProductById(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Product.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // CRUD Actions
  Future<void> saveProduct(Product product) async {
    if (product.id.isEmpty) {
      await _db.collection('products').add(product.toMap());
    } else {
      await _db.collection('products').doc(product.id).set(product.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  Future<void> saveDepartment(Department department) async {
    if (department.id.isEmpty) {
      await _db.collection('departments').add(department.toMap());
    } else {
      await _db.collection('departments').doc(department.id).set(department.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteDepartment(String id) async {
    await _db.collection('departments').doc(id).delete();
  }

  Future<void> saveCategory(CategoryItem category) async {
    if (category.id.isEmpty) {
      await _db.collection('categories').add(category.toMap());
    } else {
      await _db.collection('categories').doc(category.id).set(category.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Future<void> saveSubcategory(Subcategory subcategory) async {
    if (subcategory.id.isEmpty) {
      await _db.collection('subcategories').add(subcategory.toMap());
    } else {
      await _db.collection('subcategories').doc(subcategory.id).set(subcategory.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteSubcategory(String id) async {
    await _db.collection('subcategories').doc(id).delete();
  }

  Future<void> saveHeroBanner(HeroBannerItem banner) async {
    if (banner.id.isEmpty) {
      await _db.collection('hero_banners').add(banner.toMap());
    } else {
      await _db.collection('hero_banners').doc(banner.id).set(banner.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteHeroBanner(String id) async {
    await _db.collection('hero_banners').doc(id).delete();
  }

  Future<void> saveBusinessSettings(BusinessSettings settings) async {
    await _db.collection('settings').doc('business').set(settings.toMap(), SetOptions(merge: true));
  }

  /// Initial Seed for empty database to ensure instant out-of-the-box catalog experience
  Future<void> seedDefaultDataIfEmpty() async {
    final deptSnap = await _db.collection('departments').limit(1).get();
    if (deptSnap.docs.isNotEmpty) return; // Already seeded or populated

    // Seed Business Settings
    await saveBusinessSettings(BusinessSettings(
      whatsAppNumber: '+919876543210',
      contactNumbers: const ['+919876543210'],
      email: 'vip@hashzone.com',
      storeAddress: 'HASH ZONE Flagship Store, Fashion Avenue, Metro City',
      googleMapsUrl: 'https://maps.google.com',
      businessHours: 'Mon - Sat: 10:00 AM - 9:00 PM | Sun: 11:00 AM - 6:00 PM',
      announcementText: 'WELCOME TO HASH ZONE | CURATED DIGITAL CATALOG',
      cloudinaryCloudName: 'um227ll2',
      cloudinaryUploadPreset: 'hashzone_products',
      cloudinaryFolder: 'hashzone/products',
    ));

    // Seed Hero Banners
    await _db.collection('hero_banners').add(HeroBannerItem(
      id: '',
      imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=1600&auto=format&fit=crop',
      title: 'PREMIUM ESSENTIALS',
      subtitle: 'AUTUMN / WINTER EXCLUSIVE CATALOG 2026',
      buttonText: 'BROWSE CATALOG',
      linkUrl: '/products',
      order: 1,
    ).toMap());

    await _db.collection('hero_banners').add(HeroBannerItem(
      id: '',
      imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=1600&auto=format&fit=crop',
      title: 'HAUTE COUTURE MENSWEAR',
      subtitle: 'HANDCRAFTED TAILORING & MODERN SILHOUETTES',
      buttonText: 'VIEW MENSWEAR',
      linkUrl: '/products?department=menswear',
      order: 2,
    ).toMap());

    // Seed Departments
    final dMen = await _db.collection('departments').add(Department(
      id: '',
      name: 'MENSWEAR',
      slug: 'menswear',
      description: 'Modern tailoring, outerwear and casual elegance.',
      imageUrl: 'https://images.unsplash.com/photo-1617137968427-85924c800a22?q=80&w=800&auto=format&fit=crop',
      order: 1,
    ).toMap());

    final dWomen = await _db.collection('departments').add(Department(
      id: '',
      name: 'WOMENSWEAR',
      slug: 'womenswear',
      description: 'Sophisticated silhouettes, premium silk, and statement wear.',
      imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=800&auto=format&fit=crop',
      order: 2,
    ).toMap());

    final dAcc = await _db.collection('departments').add(Department(
      id: '',
      name: 'ACCESSORIES & LEATHER',
      slug: 'accessories',
      description: 'Handcrafted leather bags, footwear, belts and timepiece accessories.',
      imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?q=80&w=800&auto=format&fit=crop',
      order: 3,
    ).toMap());

    // Seed Categories for Menswear
    final cOuterwear = await _db.collection('categories').add(CategoryItem(
      id: '',
      name: 'Jackets & Coats',
      slug: 'jackets-coats',
      departmentId: dMen.id,
      order: 1,
    ).toMap());

    final cShirts = await _db.collection('categories').add(CategoryItem(
      id: '',
      name: 'Shirts & Polos',
      slug: 'shirts-polos',
      departmentId: dMen.id,
      order: 2,
    ).toMap());

    await _db.collection('categories').add(CategoryItem(
      id: '',
      name: 'Trousers & Denim',
      slug: 'trousers-denim',
      departmentId: dMen.id,
      order: 3,
    ).toMap());

    // Seed Categories for Womenswear
    final cDresses = await _db.collection('categories').add(CategoryItem(
      id: '',
      name: 'Dresses & Gowns',
      slug: 'dresses-gowns',
      departmentId: dWomen.id,
      order: 1,
    ).toMap());

    // Seed Sample Products with Cloudinary metadata structure
    await _db.collection('products').add(Product(
      id: '',
      title: 'Monochrome Wool Blend Overcoat',
      sku: 'HZ-COAT-001',
      departmentId: dMen.id,
      categoryId: cOuterwear.id,
      price: '₹24,990',
      images: [
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/coat_001',
          isCover: true,
          displayOrder: 1,
          width: 800,
          height: 1000,
        ),
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1544441893-675973e31985?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/coat_001_alt',
          isCover: false,
          displayOrder: 2,
          width: 800,
          height: 1000,
        ),
      ],
      description: 'Tailored double-breasted overcoat engineered from heavy Italian virgin wool blend. Minimalist black finish with satin interior lining.',
      specifications: {
        'Material': '80% Virgin Wool, 20% Cashmere',
        'Fit': 'Tailored Slim Fit',
        'Care': 'Dry Clean Only',
        'Origin': 'Handcrafted'
      },
      isFeatured: true,
      isOffer: false,
      tags: ['Premium', 'Winter', 'Overcoat', 'Black'],
      availableSizes: ['S', 'M', 'L', 'XL'],
    ).toMap());

    await _db.collection('products').add(Product(
      id: '',
      title: 'Signature Minimalist Silk Shirt',
      sku: 'HZ-SHIRT-002',
      departmentId: dMen.id,
      categoryId: cShirts.id,
      price: '₹8,990',
      images: [
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/shirt_002',
          isCover: true,
          displayOrder: 1,
          width: 800,
          height: 1000,
        ),
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/shirt_002_alt',
          isCover: false,
          displayOrder: 2,
          width: 800,
          height: 1000,
        ),
      ],
      description: 'Clean silhouette black silk button-down shirt featuring concealed placket and French cuffs.',
      specifications: {
        'Material': '100% Pure Mulberry Silk',
        'Fit': 'Modern Relaxed',
        'Color': 'Obsidian Black',
      },
      isFeatured: true,
      isOffer: false,
      tags: ['Shirt', 'Silk', 'Black'],
    ).toMap());

    await _db.collection('products').add(Product(
      id: '',
      title: 'Avant-Garde Pleated Evening Dress',
      sku: 'HZ-DRESS-003',
      departmentId: dWomen.id,
      categoryId: cDresses.id,
      price: '₹32,500',
      images: [
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/dress_003',
          isCover: true,
          displayOrder: 1,
          width: 800,
          height: 1000,
        ),
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/dress_003_alt',
          isCover: false,
          displayOrder: 2,
          width: 800,
          height: 1000,
        ),
      ],
      description: 'Flowing floor-length black evening gown with sculptural asymmetric neckline and pleated waist detailing.',
      specifications: {
        'Material': 'Silk Chiffon & Satin',
        'Length': 'Floor Length',
        'Occasion': 'Black Tie / Evening',
      },
      isFeatured: true,
      isOffer: true,
      tags: ['Women', 'Gown', 'Evening Wear'],
    ).toMap());

    await _db.collection('products').add(Product(
      id: '',
      title: 'Executive Leather Duffel Bag',
      sku: 'HZ-BAG-004',
      departmentId: dAcc.id,
      categoryId: '',
      price: '₹18,500',
      images: [
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/bag_004',
          isCover: true,
          displayOrder: 1,
          width: 800,
          height: 1000,
        ),
        CloudinaryImage(
          url: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?q=80&w=800&auto=format&fit=crop',
          publicId: 'hashzone/products/bag_004_alt',
          isCover: false,
          displayOrder: 2,
          width: 800,
          height: 1000,
        ),
      ],
      description: 'Full-grain matte black leather weekend travel bag with gunmetal hardware and padded laptop sleeve.',
      specifications: {
        'Material': '100% Italian Full-Grain Leather',
        'Dimensions': '50 x 28 x 25 cm',
        'Hardware': 'Gunmetal Matte Finish',
      },
      isFeatured: false,
      isOffer: true,
      tags: ['Leather', 'Bag', 'Accessories'],
    ).toMap());
  }

  // Supply Network Methods
  Stream<List<SupplyState>> streamSupplyNetwork() {
    return _db
        .collection('supply_network')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupplyState.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveSupplyState(SupplyState state) async {
    if (state.id.isEmpty) {
      await _db.collection('supply_network').add(state.toMap());
    } else {
      await _db.collection('supply_network').doc(state.id).set(state.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteSupplyState(String id) async {
    await _db.collection('supply_network').doc(id).delete();
  }
}
