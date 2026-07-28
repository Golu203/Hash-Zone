import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as provider;

import '../../models/cloudinary_image.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../repositories/image_upload_repository.dart';
import '../../widgets/upload_progress_widget.dart';
import '../../widgets/image_cropper_modal.dart';

class AdminProductEditScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AdminProductEditScreen({super.key, this.productId});

  @override
  ConsumerState<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends ConsumerState<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedDeptId = '';
  String _selectedCatId = '';
  String _selectedSubCatId = '';
  bool _isFeatured = false;
  bool _isOffer = false;
  Map<String, String> _specifications = {};

  final TextEditingController _specKeyController = TextEditingController();
  final TextEditingController _specValController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductData();
    });
  }

  List<String> _selectedSizes = [];

  void _loadProductData() {
    final uploadRepo = ref.read(imageUploadRepositoryProvider);
    uploadRepo.clear();

    if (widget.productId != null && widget.productId!.isNotEmpty) {
      final catalog = provider.Provider.of<CatalogProvider>(context, listen: false);
      try {
        final p = catalog.products.firstWhere((item) => item.id == widget.productId);
        _titleController.text = p.title;
        _skuController.text = p.sku;
        _priceController.text = p.price;
        if (p.offerPrice != null) {
          _offerPriceController.text = p.offerPrice!.toStringAsFixed(0);
        }
        _descriptionController.text = p.description;
        _tagsController.text = p.tags.join(', ');
        _selectedDeptId = p.departmentId;
        _selectedCatId = p.categoryId;
        _selectedSubCatId = p.subcategoryId;
        _isFeatured = p.isFeatured;
        _isOffer = p.isOffer;
        _specifications = Map<String, String>.from(p.specifications);
        _selectedSizes = List<String>.from(p.availableSizes);

        // Load existing images into upload repository
        uploadRepo.initExistingImages(p.images);
        setState(() {});
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _specKeyController.dispose();
    _specValController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    final uploadRepo = ref.read(imageUploadRepositoryProvider);
    final business = provider.Provider.of<BusinessProvider>(context, listen: false);

    List<ImageFileData> pickedFiles = [];

    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) {
      final source = await _showImageSourceDialog(context);
      if (source == null) return;

      if (source == ImageSource.camera) {
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.camera);
        if (file != null) {
          final bytes = await file.readAsBytes();
          pickedFiles.add(ImageFileData(bytes: bytes, filename: file.name));
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true,
        );
        if (result != null) {
          for (final f in result.files) {
            if (f.bytes != null) {
              pickedFiles.add(ImageFileData(bytes: f.bytes!, filename: f.name));
            }
          }
        }
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result != null) {
        for (final f in result.files) {
          if (f.bytes != null) {
            pickedFiles.add(ImageFileData(bytes: f.bytes!, filename: f.name));
          }
        }
      }
    }

    if (pickedFiles.isNotEmpty) {
      final List<ImageFileData> croppedFiles = [];

      for (final f in pickedFiles) {
        final croppedBytes = await HZImageCropperModal.cropImage(
          context,
          imageBytes: f.bytes,
          filename: f.filename,
          initialRatio: CropAspectRatioOption.gallery4x3,
        );

        if (croppedBytes != null) {
          croppedFiles.add(ImageFileData(bytes: croppedBytes, filename: f.filename));
        }
      }

      if (croppedFiles.isNotEmpty) {
        uploadRepo.addFiles(croppedFiles);

        await uploadRepo.uploadAll(
          cloudName: business.settings.cloudinaryCloudName,
          uploadPreset: business.settings.cloudinaryUploadPreset,
          folder: business.settings.cloudinaryFolder,
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final uploadRepo = ref.read(imageUploadRepositoryProvider);

    if (uploadRepo.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 product image.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (uploadRepo.isUploadingAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for all images to complete uploading.'), backgroundColor: Colors.amber),
      );
      return;
    }

    if (!uploadRepo.allUploadsSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Some images failed to upload. Please retry or remove them before saving.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    final admin = provider.Provider.of<AdminProvider>(context, listen: false);

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<CloudinaryImage> finalImages = uploadRepo.getFinalCloudinaryImages();

    final double? parsedOfferPrice = _isOffer && _offerPriceController.text.trim().isNotEmpty
        ? double.tryParse(_offerPriceController.text.trim())
        : null;

    final product = Product(
      id: widget.productId ?? '',
      title: _titleController.text.trim(),
      sku: _skuController.text.trim(),
      departmentId: _selectedDeptId,
      categoryId: _selectedCatId,
      subcategoryId: _selectedSubCatId,
      price: _priceController.text.trim(),
      offerPrice: parsedOfferPrice,
      images: finalImages,
      description: _descriptionController.text.trim(),
      specifications: _specifications,
      isFeatured: _isFeatured,
      isOffer: _isOffer,
      tags: tags,
      availableSizes: _selectedSizes,
    );

    try {
      await admin.saveProduct(product);
      if (mounted) context.go('/admin/products');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadCoverImage() async {
    final uploadRepo = ref.read(imageUploadRepositoryProvider);
    final business = provider.Provider.of<BusinessProvider>(context, listen: false);

    ImageFileData? pickedFile;

    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) {
      final source = await _showImageSourceDialog(context);
      if (source == null) return;

      if (source == ImageSource.camera) {
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.camera);
        if (file != null) {
          final bytes = await file.readAsBytes();
          pickedFile = ImageFileData(bytes: bytes, filename: file.name);
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
          final f = result.files.first;
          pickedFile = ImageFileData(bytes: f.bytes!, filename: f.name);
        }
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final f = result.files.first;
        pickedFile = ImageFileData(bytes: f.bytes!, filename: f.name);
      }
    }

    if (pickedFile != null) {
      final croppedBytes = await HZImageCropperModal.cropImage(
        context,
        imageBytes: pickedFile.bytes,
        filename: pickedFile.filename,
        initialRatio: CropAspectRatioOption.product3x4,
      );

      if (croppedBytes != null) {
        uploadRepo.addFiles([ImageFileData(bytes: croppedBytes, filename: pickedFile.filename)]);
        if (uploadRepo.tasks.isNotEmpty) {
          final newTaskId = uploadRepo.tasks.last.id;
          uploadRepo.setCoverImage(newTaskId);
        }

        await uploadRepo.uploadAll(
          cloudName: business.settings.cloudinaryCloudName,
          uploadPreset: business.settings.cloudinaryUploadPreset,
          folder: business.settings.cloudinaryFolder,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = provider.Provider.of<CatalogProvider>(context);
    final business = provider.Provider.of<BusinessProvider>(context);
    final uploadRepo = ref.watch(imageUploadRepositoryProvider);

    final categories = _selectedDeptId.isNotEmpty
        ? catalog.getCategoriesForDepartment(_selectedDeptId)
        : catalog.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.productId == null ? 'ADD NEW PRODUCT' : 'EDIT PRODUCT',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: const Color(0xFF000000),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => context.go('/admin/products'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width >= 900 ? 32 : 16,
          vertical: 32,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Help Banner
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done, color: Color(0xFF000000), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cloudinary Storage (${business.settings.cloudinaryCloudName}): Upload a dedicated Cover Image or gallery images. Use the interactive 3:4 visible cropper to preserve scale and exact image size.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Upload Section with Dedicated Cover Image Button & Format Specs
              Text(
                'PRODUCT IMAGES (${uploadRepo.tasks.length})',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF000000)),
              ),
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = MediaQuery.of(context).size.width < 750;

                  final coverBtnCol = Column(
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: uploadRepo.isUploadingAny ? null : _pickAndUploadCoverImage,
                        icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                        label: const Text('UPLOAD DEDICATED COVER IMAGE'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFBEB),
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ratio 3:4 Portrait (Recommended: 900x1200 px)',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                      ),
                    ],
                  );

                  final galleryBtnCol = Column(
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: uploadRepo.isUploadingAny ? null : _pickAndUploadImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: const Text('ADD GALLERY IMAGES'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ratio 4:3 Landscape (Recommended: 1200x900 px)',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        coverBtnCol,
                        const SizedBox(height: 16),
                        galleryBtnCol,
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: coverBtnCol),
                        const SizedBox(width: 16),
                        Expanded(child: galleryBtnCol),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // Upload Task Cards List
              if (uploadRepo.tasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF888888)),
                      const SizedBox(height: 12),
                      Text(
                        'No product images selected',
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF333333)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click above to select multiple high-resolution clothing images',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888)),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: uploadRepo.tasks.length,
                  itemBuilder: (context, index) {
                    final task = uploadRepo.tasks[index];
                    return UploadProgressWidget(
                      key: ValueKey(task.id),
                      task: task,
                      onSetCover: () => uploadRepo.setCoverImage(task.id),
                      onRemove: () => uploadRepo.removeTask(task.id),
                      onRetry: () => uploadRepo.retryTask(
                        task.id,
                        cloudName: business.settings.cloudinaryCloudName,
                        uploadPreset: business.settings.cloudinaryUploadPreset,
                        folder: business.settings.cloudinaryFolder,
                      ),
                      onMoveUp: index > 0 ? () => uploadRepo.reorderTasks(index, index - 1) : null,
                      onMoveDown: index < uploadRepo.tasks.length - 1 ? () => uploadRepo.reorderTasks(index, index + 2) : null,
                    );
                  },
                ),

              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = MediaQuery.of(context).size.width < 750;
                  final titleField = TextFormField(
                    controller: _titleController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Product Title'),
                    validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                  );

                  final skuField = TextFormField(
                    controller: _skuController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'SKU Code (e.g. HZ-001)'),
                    validator: (v) => v == null || v.isEmpty ? 'SKU required' : null,
                  );

                  final priceField = TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.text,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Price (Optional - e.g. ₹999, On Request)',
                      hintText: 'Leave empty or type custom price',
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        titleField,
                        const SizedBox(height: 12),
                        skuField,
                        const SizedBox(height: 12),
                        priceField,
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(flex: 2, child: titleField),
                        const SizedBox(width: 16),
                        Expanded(child: skuField),
                        const SizedBox(width: 16),
                        Expanded(child: priceField),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              // Segment & Category Dropdowns
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = MediaQuery.of(context).size.width < 750;
                  final segmentDropdown = DropdownButtonFormField<String>(
                    initialValue: _selectedDeptId.isNotEmpty ? _selectedDeptId : null,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Segment'),
                    items: catalog.departments.map((d) {
                      return DropdownMenuItem(value: d.id, child: Text(d.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDeptId = val;
                          _selectedCatId = '';
                          final selectedDept = catalog.getDepartmentById(val);
                          if (selectedDept != null && !selectedDept.isSizeApplicable) {
                            _selectedSizes.clear();
                          }
                        });
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Segment required' : null,
                  );

                  final categoryDropdown = DropdownButtonFormField<String>(
                    initialValue: _selectedCatId.isNotEmpty ? _selectedCatId : null,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCatId = val);
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Category required' : null,
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        segmentDropdown,
                        const SizedBox(height: 12),
                        categoryDropdown,
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: segmentDropdown),
                        const SizedBox(width: 16),
                        Expanded(child: categoryDropdown),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              // Dynamic Size Selection Section
              Builder(
                builder: (context) {
                  final dept = catalog.getDepartmentById(_selectedDeptId);
                  final isSizeEnabled = dept == null ? true : dept.isSizeApplicable;
                  const presetSizes = [
                    'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', 'Free Size',
                    '16', '18', '20', '22', '24', '26', '28', '30', '32', '34', '36', '38', '40', '42', '44', '46'
                  ];

                  return Opacity(
                    opacity: isSizeEnabled ? 1.0 : 0.35,
                    child: AbsorbPointer(
                      absorbing: !isSizeEnabled,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isSizeEnabled ? Colors.white : const Color(0xFFEBEBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSizeEnabled ? const Color(0xFF000000) : Colors.red[800]!,
                            width: isSizeEnabled ? 1.5 : 2.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'AVAILABLE SIZES FOR THIS PRODUCT',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: isSizeEnabled ? const Color(0xFF111111) : Colors.red[900],
                                      ),
                                    ),
                                    if (!isSizeEnabled)
                                      Container(
                                        margin: const EdgeInsets.only(left: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.red[700]!),
                                        ),
                                        child: Text(
                                          'OFF / SIZES DISABLED',
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red[900]),
                                        ),
                                      ),
                                  ],
                                ),
                                if (isSizeEnabled && _selectedSizes.isNotEmpty)
                                  TextButton(
                                    onPressed: () => setState(() => _selectedSizes.clear()),
                                    child: Text('Clear Sizes', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666))),
                                  ),
                              ],
                            ),
                            if (!isSizeEnabled) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Sizes are turned OFF for ${dept.name}. Toggle sizes ON in Taxonomies to enable size selection.',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red[900]),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: presetSizes.map((size) {
                                final isSelected = isSizeEnabled && _selectedSizes.contains(size);
                                return FilterChip(
                                  label: Text(size),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF000000),
                                  disabledColor: const Color(0xFFE5E5E5),
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF333333),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: isSizeEnabled
                                      ? (val) {
                                          setState(() {
                                            if (val) {
                                              _selectedSizes.add(size);
                                            } else {
                                              _selectedSizes.remove(size);
                                            }
                                          });
                                        }
                                      : null,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Description & Tags
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: GoogleFonts.inter(color: Colors.black),
                decoration: const InputDecoration(labelText: 'Product Description'),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _tagsController,
                style: GoogleFonts.inter(color: Colors.black),
                decoration: const InputDecoration(labelText: 'Search Tags (comma separated, e.g. Premium, Silk, Black)'),
              ),

              const SizedBox(height: 24),

              // Featured & Offer Toggles
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = MediaQuery.of(context).size.width < 750;
                  final featuredSwitch = SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Show in Featured Carousel', style: GoogleFonts.inter(color: const Color(0xFF111111))),
                    value: _isFeatured,
                    activeThumbColor: const Color(0xFF000000),
                    onChanged: (v) => setState(() => _isFeatured = v),
                  );

                  final offerSwitch = SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Flag as Special Offer', style: GoogleFonts.inter(color: const Color(0xFF111111))),
                    value: _isOffer,
                    activeThumbColor: const Color(0xFFD32F2F),
                    onChanged: (v) => setState(() => _isOffer = v),
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        featuredSwitch,
                        const SizedBox(height: 8),
                        offerSwitch,
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: featuredSwitch),
                        const SizedBox(width: 16),
                        Expanded(child: offerSwitch),
                      ],
                    );
                  }
                },
              ),

              // Offer Price Input Field (Appears when Flag as Special Offer is ON)
              if (_isOffer) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPECIAL OFFER DISCOUNT PRICE',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the discounted offer price. On the customer website, the original price (₹${_priceController.text}) will be strikethrough with this offer price highlighted.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78350F)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _offerPriceController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Special Offer Price (₹)',
                          hintText: 'e.g. 999',
                          prefixText: '₹ ',
                        ),
                        validator: (v) {
                          if (_isOffer && (v == null || v.trim().isEmpty)) {
                            return 'Offer price required when Special Offer is ON';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Specifications Table Section
              Text(
                'SPECIFICATIONS & DETAILS TABLE',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF666666)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  children: [
                    ..._specifications.entries.map((e) => ListTile(
                          title: Text('${e.key}: ${e.value}', style: GoogleFonts.inter(color: const Color(0xFF111111))),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                            onPressed: () => setState(() => _specifications.remove(e.key)),
                          ),
                        )),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = MediaQuery.of(context).size.width < 750;
                        final keyField = TextField(
                          controller: _specKeyController,
                          style: GoogleFonts.inter(color: Colors.black),
                          decoration: const InputDecoration(hintText: 'Key (e.g. Material)'),
                        );

                        final valField = TextField(
                          controller: _specValController,
                          style: GoogleFonts.inter(color: Colors.black),
                          decoration: const InputDecoration(hintText: 'Value (e.g. 100% Pure Silk)'),
                        );

                        final addBtn = ElevatedButton(
                          onPressed: () {
                            if (_specKeyController.text.isNotEmpty && _specValController.text.isNotEmpty) {
                              setState(() {
                                _specifications[_specKeyController.text.trim()] = _specValController.text.trim();
                                _specKeyController.clear();
                                _specValController.clear();
                              });
                            }
                          },
                          child: const Text('ADD'),
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              keyField,
                              const SizedBox(height: 12),
                              valField,
                              const SizedBox(height: 12),
                              SizedBox(width: double.infinity, child: addBtn),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: keyField),
                              const SizedBox(width: 12),
                              Expanded(child: valField),
                              const SizedBox(width: 12),
                              addBtn,
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isSaving || uploadRepo.isUploadingAny || !uploadRepo.allUploadsSuccessful)
                      ? null
                      : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: uploadRepo.allUploadsSuccessful ? Colors.black : const Color(0xFF888888),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          uploadRepo.isUploadingAny
                              ? 'UPLOADING IMAGES TO CLOUDINARY...'
                              : !uploadRepo.allUploadsSuccessful
                                  ? 'PLEASE COMPLETE IMAGE UPLOADS FIRST'
                                  : 'SAVE PRODUCT TO CLOUDINARY CMS',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'UPLOAD IMAGE',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture with Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Select from Files'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
