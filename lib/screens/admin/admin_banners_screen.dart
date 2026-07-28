import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as provider;
import '../../models/hero_banner.dart';
import '../../providers/admin_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/catalog_provider.dart';

import '../../widgets/image_cropper_modal.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _btnController = TextEditingController();
  final _linkController = TextEditingController(text: '/products');

  String _uploadedBannerImageUrl = '';
  bool _isUploadingBannerImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _btnController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadBannerImage() async {
    final business = provider.Provider.of<BusinessProvider>(context, listen: false);
    final admin = provider.Provider.of<AdminProvider>(context, listen: false);

    Uint8List? pickedBytes;
    String? pickedFilename;

    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) {
      final source = await _showImageSourceDialog(context);
      if (source == null) return;

      if (source == ImageSource.camera) {
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.camera);
        if (file != null) {
          pickedBytes = await file.readAsBytes();
          pickedFilename = file.name;
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
          pickedBytes = result.files.first.bytes!;
          pickedFilename = result.files.first.name;
        }
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        pickedBytes = result.files.first.bytes!;
        pickedFilename = result.files.first.name;
      }
    }

    if (pickedBytes != null && pickedFilename != null) {
      final croppedBytes = await HZImageCropperModal.cropImage(
        context,
        imageBytes: pickedBytes,
        filename: pickedFilename,
        initialRatio: CropAspectRatioOption.banner16x9,
      );

      if (croppedBytes != null) {
        setState(() => _isUploadingBannerImage = true);

        try {
          final url = await admin.uploadImageBytes(
            croppedBytes,
            pickedFilename,
            cloudinaryCloudName: business.settings.cloudinaryCloudName,
            cloudinaryUploadPreset: business.settings.cloudinaryUploadPreset,
          );

          setState(() {
            _uploadedBannerImageUrl = url;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Banner image uploaded successfully!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) setState(() => _isUploadingBannerImage = false);
        }
      }
    }
  }

  void _addBanner(AdminProvider admin) {
    if (_uploadedBannerImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a banner image.')),
      );
      return;
    }

    final banner = HeroBannerItem(
      id: '',
      imageUrl: _uploadedBannerImageUrl,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      buttonText: _btnController.text.trim(),
      linkUrl: _linkController.text.trim(),
      order: 1,
      isActive: true,
    );

    admin.saveHeroBanner(banner);
    _titleController.clear();
    _subtitleController.clear();
    setState(() {
      _uploadedBannerImageUrl = '';
    });
  }

  // Edit Hero Banner Modal Dialog
  void _openEditBannerModal(BuildContext context, AdminProvider admin, HeroBannerItem banner) {
    final editTitleController = TextEditingController(text: banner.title);
    final editSubtitleController = TextEditingController(text: banner.subtitle);
    final editBtnController = TextEditingController(text: banner.buttonText);
    final editLinkController = TextEditingController(text: banner.linkUrl);
    String editImageUrl = banner.imageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black, width: 2.0),
              ),
              title: Text(
                'EDIT HERO BANNER: ${banner.title}',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (editImageUrl.isNotEmpty)
                            Container(
                              width: 100,
                              height: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black),
                                image: DecorationImage(image: NetworkImage(editImageUrl), fit: BoxFit.cover),
                              ),
                            ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      final business = provider.Provider.of<BusinessProvider>(context, listen: false);
                                      Uint8List? pickedBytes;
                                      String? pickedFilename;

                                      final isMobile = MediaQuery.of(context).size.width < 900;
                                      if (isMobile) {
                                        final source = await _showImageSourceDialog(context);
                                        if (source != null) {
                                          if (source == ImageSource.camera) {
                                            final picker = ImagePicker();
                                            final file = await picker.pickImage(source: ImageSource.camera);
                                            if (file != null) {
                                              pickedBytes = await file.readAsBytes();
                                              pickedFilename = file.name;
                                            }
                                          } else {
                                            final result = await FilePicker.platform.pickFiles(
                                              type: FileType.image,
                                              allowMultiple: false,
                                              withData: true,
                                            );
                                            if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
                                              pickedBytes = result.files.first.bytes!;
                                              pickedFilename = result.files.first.name;
                                            }
                                          }
                                        }
                                      } else {
                                        final result = await FilePicker.platform.pickFiles(
                                          type: FileType.image,
                                          allowMultiple: false,
                                          withData: true,
                                        );
                                        if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
                                          pickedBytes = result.files.first.bytes!;
                                          pickedFilename = result.files.first.name;
                                        }
                                      }

                                      if (pickedBytes != null && pickedFilename != null) {
                                        final croppedBytes = await HZImageCropperModal.cropImage(
                                          context,
                                          imageBytes: pickedBytes,
                                          filename: pickedFilename,
                                          initialRatio: CropAspectRatioOption.banner16x9,
                                        );

                                        if (croppedBytes != null) {
                                          setDialogState(() => isUploading = true);
                                          try {
                                            final url = await admin.uploadImageBytes(
                                              croppedBytes,
                                              pickedFilename,
                                              cloudinaryCloudName: business.settings.cloudinaryCloudName,
                                              cloudinaryUploadPreset: business.settings.cloudinaryUploadPreset,
                                            );
                                            setDialogState(() {
                                              editImageUrl = url;
                                              isUploading = false;
                                            });
                                          } catch (_) {
                                            setDialogState(() => isUploading = false);
                                          }
                                        }
                                      }
                                    },
                              icon: isUploading
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.cloud_upload_outlined, size: 16),
                              label: Text(editImageUrl.isEmpty ? 'UPLOAD IMAGE' : 'CHANGE IMAGE', style: const TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: editTitleController,
                        style: GoogleFonts.inter(color: Colors.black),
                        decoration: const InputDecoration(labelText: 'Main Banner Title'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: editSubtitleController,
                        style: GoogleFonts.inter(color: Colors.black),
                        decoration: const InputDecoration(labelText: 'Subtitle / Header Tagline'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: editBtnController,
                              style: GoogleFonts.inter(color: Colors.black),
                              decoration: const InputDecoration(labelText: 'Button Text'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: editLinkController,
                              style: GoogleFonts.inter(color: Colors.black),
                              decoration: const InputDecoration(labelText: 'Target Link Route'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updated = HeroBannerItem(
                      id: banner.id,
                      imageUrl: editImageUrl,
                      title: editTitleController.text.trim(),
                      subtitle: editSubtitleController.text.trim(),
                      buttonText: editBtnController.text.trim(),
                      linkUrl: editLinkController.text.trim(),
                      order: banner.order,
                      isActive: banner.isActive,
                    );
                    await admin.saveHeroBanner(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('SAVE CHANGES'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = provider.Provider.of<CatalogProvider>(context);
    final admin = provider.Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'HERO BANNERS MANAGEMENT',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width >= 900 ? 32 : 16,
          vertical: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banners List
            Text(
              'ACTIVE HERO SLIDESHOW BANNERS',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF000000)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF000000), width: 2.0),
              ),
              child: Column(
                children: [
                  if (catalog.heroBanners.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hero banners added yet.'),
                    )
                  else
                    ...catalog.heroBanners.map((b) {
                      final isMobileOnBanners = MediaQuery.of(context).size.width < 750;

                      if (isMobileOnBanners) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black),
                                      image: DecorationImage(
                                        image: NetworkImage(b.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                                        Text(b.subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                                    tooltip: 'Edit Hero Banner',
                                    onPressed: () => _openEditBannerModal(context, admin, b),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Delete Banner',
                                    onPressed: () => admin.deleteHeroBanner(b.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: Container(
                            width: 70,
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black),
                              image: DecorationImage(
                                image: NetworkImage(b.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(b.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                          subtitle: Text(b.subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                                tooltip: 'Edit Hero Banner',
                                onPressed: () => _openEditBannerModal(context, admin, b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Delete Banner',
                                onPressed: () => admin.deleteHeroBanner(b.id),
                              ),
                            ],
                          ),
                        );
                      }
                    }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'CREATE NEW HERO BANNER',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF000000)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF000000), width: 2.0),
              ),
              child: Column(
                children: [
                   // Image Upload Button & Preview (Responsive Layout)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = MediaQuery.of(context).size.width < 750;
                      final uploadBtn = OutlinedButton.icon(
                        onPressed: _isUploadingBannerImage ? null : _pickAndUploadBannerImage,
                        icon: _isUploadingBannerImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.cloud_upload_outlined, color: Colors.black),
                        label: Text(
                          _uploadedBannerImageUrl.isEmpty
                              ? 'UPLOAD & CROP BANNER'
                              : 'CHANGE BANNER',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      );

                      if (_uploadedBannerImageUrl.isNotEmpty) {
                        final previewContainer = Container(
                          width: isMobile ? double.infinity : 100,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF000000)),
                            image: DecorationImage(
                              image: NetworkImage(_uploadedBannerImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              previewContainer,
                              const SizedBox(height: 12),
                              SizedBox(width: double.infinity, child: uploadBtn),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              previewContainer,
                              const SizedBox(width: 16),
                              Expanded(child: uploadBtn),
                            ],
                          );
                        }
                      } else {
                        return SizedBox(width: double.infinity, child: uploadBtn);
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ratio 21:9 Ultra-Wide Screen (Recommended: 2100x900 px)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Main Title (e.g. PREMIUM ESSENTIALS)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subtitleController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Subtitle / Collection Header'),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Column(
                          children: [
                            TextFormField(
                              controller: _btnController,
                              style: GoogleFonts.inter(color: Colors.black),
                              decoration: const InputDecoration(labelText: 'Button Label'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _linkController,
                              style: GoogleFonts.inter(color: Colors.black),
                              decoration: const InputDecoration(labelText: 'Target URL / Route'),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _btnController,
                                style: GoogleFonts.inter(color: Colors.black),
                                decoration: const InputDecoration(labelText: 'Button Label'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _linkController,
                                style: GoogleFonts.inter(color: Colors.black),
                                decoration: const InputDecoration(labelText: 'Target URL / Route'),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _addBanner(admin),
                    child: const Text('CREATE HERO BANNER'),
                  ),
                ],
              ),
            ),
          ],
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
