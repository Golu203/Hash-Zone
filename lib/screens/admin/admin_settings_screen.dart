import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/business_settings.dart';
import '../../providers/admin_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/image_cropper_modal.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _whatsAppController = TextEditingController();
  final List<TextEditingController> _contactControllers = [];
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapsController = TextEditingController();
  final _hoursController = TextEditingController();
  final _announcementController = TextEditingController();
  final _cloudNameController = TextEditingController(text: 'um227ll2');
  final _presetController = TextEditingController(text: 'hashzone_products');
  final _folderController = TextEditingController(text: 'hashzone/products');

  // Social Media Controllers
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _youtubeController = TextEditingController();

  // Promo Popup Controllers & State
  bool _isPopupActive = false;
  bool _enableShoppingCart = false;
  final _popupLinkController = TextEditingController(text: '/products');
  final _popupActionTextController = TextEditingController(text: 'EXPLORE SPECIAL OFFER');
  String _uploadedPopupImageUrl = '';
  bool _isUploadingPopupImage = false;

  bool _isFormInitialized = false;
  bool _isSaving = false;

  void _populateFormFields(BusinessSettings s) {
    _whatsAppController.text = s.whatsAppNumber;
    _contactControllers.clear();
    for (var contact in s.contactNumbers) {
      _contactControllers.add(TextEditingController(text: contact));
    }
    if (_contactControllers.isEmpty) {
      _contactControllers.add(TextEditingController());
    }
    _emailController.text = s.email;
    _addressController.text = s.storeAddress;
    _mapsController.text = s.googleMapsUrl;
    _hoursController.text = s.businessHours;
    _announcementController.text = s.announcementText;
    _cloudNameController.text = s.cloudinaryCloudName.isNotEmpty ? s.cloudinaryCloudName : 'um227ll2';
    _presetController.text = s.cloudinaryUploadPreset.isNotEmpty ? s.cloudinaryUploadPreset : 'hashzone_products';
    _folderController.text = s.cloudinaryFolder.isNotEmpty ? s.cloudinaryFolder : 'hashzone/products';

    // Social Links
    _instagramController.text = s.socialLinks['instagram'] ?? 'https://instagram.com';
    _facebookController.text = s.socialLinks['facebook'] ?? 'https://facebook.com';
    _twitterController.text = s.socialLinks['twitter'] ?? 'https://twitter.com';
    _youtubeController.text = s.socialLinks['youtube'] ?? 'https://youtube.com';

    // Promo Popup
    _isPopupActive = s.isPopupActive;
    _uploadedPopupImageUrl = s.popupImageUrl;
    _popupLinkController.text = s.popupLinkUrl;
    _popupActionTextController.text = s.popupActionText.isNotEmpty ? s.popupActionText : 'EXPLORE SPECIAL OFFER';
    _enableShoppingCart = s.enableShoppingCart;
  }

  @override
  void dispose() {
    _whatsAppController.dispose();
    for (var c in _contactControllers) {
      c.dispose();
    }
    _emailController.dispose();
    _addressController.dispose();
    _mapsController.dispose();
    _hoursController.dispose();
    _announcementController.dispose();
    _cloudNameController.dispose();
    _presetController.dispose();
    _folderController.dispose();

    _instagramController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _popupLinkController.dispose();
    _popupActionTextController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPopupImage() async {
    final business = Provider.of<BusinessProvider>(context, listen: false);
    final admin = Provider.of<AdminProvider>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
      final file = result.files.first;

      final croppedBytes = await HZImageCropperModal.cropImage(
        context,
        imageBytes: file.bytes!,
        filename: file.name,
        initialRatio: CropAspectRatioOption.promoPopup,
      );

      if (croppedBytes != null) {
        setState(() => _isUploadingPopupImage = true);

        try {
          final url = await admin.uploadImageBytes(
            croppedBytes,
            file.name,
            cloudinaryCloudName: business.settings.cloudinaryCloudName,
            cloudinaryUploadPreset: business.settings.cloudinaryUploadPreset,
          );

          setState(() {
            _uploadedPopupImageUrl = url;
            _isUploadingPopupImage = false;
          });
        } catch (e) {
          setState(() => _isUploadingPopupImage = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Popup image upload failed: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final business = Provider.of<BusinessProvider>(context, listen: false);

    final Map<String, String> social = {
      'instagram': _instagramController.text.trim(),
      'facebook': _facebookController.text.trim(),
      'twitter': _twitterController.text.trim(),
      'youtube': _youtubeController.text.trim(),
      'whatsapp': 'https://wa.me/${_whatsAppController.text.replaceAll(RegExp(r'[^0-9]'), '')}',
    };

    final newSettings = BusinessSettings(
      whatsAppNumber: _whatsAppController.text.trim(),
      contactNumbers: _contactControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      email: _emailController.text.trim(),
      storeAddress: _addressController.text.trim(),
      googleMapsUrl: _mapsController.text.trim(),
      businessHours: _hoursController.text.trim(),
      announcementText: _announcementController.text.trim(),
      cloudinaryCloudName: _cloudNameController.text.trim(),
      cloudinaryUploadPreset: _presetController.text.trim(),
      cloudinaryFolder: _folderController.text.trim(),
      socialLinks: social,
      isPopupActive: _isPopupActive,
      popupImageUrl: _uploadedPopupImageUrl,
      popupLinkUrl: _popupLinkController.text.trim(),
      popupActionText: _popupActionTextController.text.trim(),
      enableShoppingCart: _enableShoppingCart,
    );

    try {
      await business.updateSettings(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business settings & Promo popup saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = Provider.of<BusinessProvider>(context);

    if (!_isFormInitialized) {
      _populateFormFields(business.settings);
      _isFormInitialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Text(
          'BUSINESS & CONTACT SETTINGS',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
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
            // SHOPPING CART CONFIGURATION SECTION
            Text(
              '1. SHOPPING CART CONFIGURATION',
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
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Enable Shopping Cart & Multi-Item Ordering',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                subtitle: Text(
                  _enableShoppingCart
                      ? 'Shopping Cart ENABLED: Customers can add items to cart, select sizes/quantities, and submit one combined order via WhatsApp.'
                      : 'Shopping Cart DISABLED: Single product WhatsApp inquiry flow only.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _enableShoppingCart ? Colors.green[800] : Colors.grey[700]),
                ),
                value: _enableShoppingCart,
                activeThumbColor: Colors.black,
                onChanged: (val) => setState(() => _enableShoppingCart = val),
              ),
            ),

            const SizedBox(height: 32),

            // PROMO POPUP ADVERTISEMENT SECTION
            Text(
              '2. PROMO POPUP ADVERTISEMENT',
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Enable Customer Entrance Popup Banner',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    subtitle: Text(
                      _isPopupActive
                          ? 'Popup ACTIVE: Displays image modal when customers enter the website.'
                          : 'Popup INACTIVE: Turned off.',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _isPopupActive ? Colors.green[800] : Colors.grey[700]),
                    ),
                    value: _isPopupActive,
                    activeThumbColor: Colors.black,
                    onChanged: (val) => setState(() => _isPopupActive = val),
                  ),
                  const SizedBox(height: 16),

                  // Image Upload & Crop Button (Responsive Layout)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = MediaQuery.of(context).size.width < 750;
                      final uploadBtn = OutlinedButton.icon(
                        onPressed: _isUploadingPopupImage ? null : _pickAndUploadPopupImage,
                        icon: _isUploadingPopupImage
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.cloud_upload_outlined, color: Colors.black),
                        label: Text(
                          _uploadedPopupImageUrl.isEmpty ? 'UPLOAD & CROP POPUP BANNER' : 'CHANGE POPUP BANNER',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      );

                      if (_uploadedPopupImageUrl.isNotEmpty) {
                        final previewContainer = Container(
                          width: isMobile ? double.infinity : 90,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black),
                            image: DecorationImage(image: NetworkImage(_uploadedPopupImageUrl), fit: BoxFit.cover),
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
                    'Ratio 1:1 Square (Recommended: 800x800 px)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _popupLinkController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Action Target Link URL (Leave empty for image-only popup)',
                      hintText: 'e.g. /products or https://wa.me/...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _popupActionTextController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Action Button Text (Appears below popup with right arrow if link exists)',
                      hintText: 'e.g. EXPLORE SPECIAL OFFER',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SOCIAL MEDIA LINKS SECTION
            Text(
              '3. SOCIAL MEDIA LINKS (FOOTER INTEGRATION)',
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
                  TextFormField(
                    controller: _instagramController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Instagram Page URL (e.g. https://instagram.com/hashzone)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _facebookController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Facebook Page URL (e.g. https://facebook.com/hashzone)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _twitterController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Twitter / X Profile URL'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _youtubeController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'YouTube Channel URL'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Cloudinary Section
            Text(
              '4. CLOUDINARY PERMANENT STORAGE CONFIGURATION',
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
                  TextFormField(
                    controller: _cloudNameController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Cloud Name (e.g. um227ll2)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _presetController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Upload Preset (e.g. hashzone_products)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _folderController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Target Folder (e.g. hashzone/products)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Numbers & Email
            Text(
              '5. DIRECT CONTACT CHANNELS',
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
                  TextFormField(
                    controller: _whatsAppController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'WhatsApp Business Number (with country code)'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Direct Contacts', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _contactControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Contact'),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_contactControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactControllers[index],
                              style: GoogleFonts.inter(color: Colors.black),
                              decoration: InputDecoration(labelText: 'Contact Number ${index + 1}'),
                            ),
                          ),
                          if (_contactControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _contactControllers[index].dispose();
                                  _contactControllers.removeAt(index);
                                });
                              },
                            )
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Store Email Address'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Store Location & Hours
            Text(
              '6. STORE DETAILS & ANNOUNCEMENTS',
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
                  TextFormField(
                    controller: _addressController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Store Address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mapsController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Google Maps Link / URL'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hoursController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Business Hours Text'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _announcementController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Header Announcement Banner Text'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE BUSINESS SETTINGS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
