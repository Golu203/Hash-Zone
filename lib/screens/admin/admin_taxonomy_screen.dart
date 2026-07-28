import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import '../../models/category.dart';
import '../../models/department.dart';
import '../../providers/admin_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/catalog_provider.dart';

import '../../widgets/image_cropper_modal.dart';

class AdminTaxonomyScreen extends StatefulWidget {
  const AdminTaxonomyScreen({super.key});

  @override
  State<AdminTaxonomyScreen> createState() => _AdminTaxonomyScreenState();
}

class _AdminTaxonomyScreenState extends State<AdminTaxonomyScreen> {
  final _deptNameController = TextEditingController();
  final _deptDescController = TextEditingController();
  final _catNameController = TextEditingController();

  String _catDeptId = '';
  String _uploadedDeptImageUrl = '';
  bool _isUploadingDeptImage = false;
  bool _isDeptSizeApplicable = true;

  @override
  void dispose() {
    _deptNameController.dispose();
    _deptDescController.dispose();
    _catNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadDeptImage() async {
    final business = provider.Provider.of<BusinessProvider>(context, listen: false);
    final admin = provider.Provider.of<AdminProvider>(context, listen: false);

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
        initialRatio: CropAspectRatioOption.square1x1,
      );

      if (croppedBytes != null) {
        setState(() => _isUploadingDeptImage = true);

        try {
          final url = await admin.uploadImageBytes(
            croppedBytes,
            file.name,
            cloudinaryCloudName: business.settings.cloudinaryCloudName,
            cloudinaryUploadPreset: business.settings.cloudinaryUploadPreset,
          );

          setState(() {
            _uploadedDeptImageUrl = url;
            _isUploadingDeptImage = false;
          });
        } catch (e) {
          setState(() => _isUploadingDeptImage = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  void _addDepartment(AdminProvider admin) {
    if (_deptNameController.text.trim().isEmpty) return;

    final name = _deptNameController.text.trim();
    final dept = Department(
      id: '',
      name: name,
      slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
      description: _deptDescController.text.trim(),
      imageUrl: _uploadedDeptImageUrl,
      isSizeApplicable: _isDeptSizeApplicable,
    );

    admin.saveDepartment(dept);
    _deptNameController.clear();
    _deptDescController.clear();
    setState(() {
      _uploadedDeptImageUrl = '';
      _isDeptSizeApplicable = true;
    });
  }

  void _addCategory(AdminProvider admin) {
    if (_catNameController.text.trim().isEmpty || _catDeptId.isEmpty) return;

    final name = _catNameController.text.trim();
    final cat = CategoryItem(
      id: '',
      name: name,
      slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
      departmentId: _catDeptId,
    );

    admin.saveCategory(cat);
    _catNameController.clear();
  }

  // Edit Department Dialog
  void _openEditDepartmentModal(BuildContext context, AdminProvider admin, Department dept) {
    final editNameController = TextEditingController(text: dept.name);
    final editDescController = TextEditingController(text: dept.description);
    bool editSizeOn = dept.isSizeApplicable;
    String editImageUrl = dept.imageUrl;
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
                'EDIT SEGMENT: ${dept.name}',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: editNameController,
                        style: GoogleFonts.inter(color: Colors.black),
                        decoration: const InputDecoration(labelText: 'Segment Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: editDescController,
                        style: GoogleFonts.inter(color: Colors.black),
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1.0),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Enable Sizes for this Segment',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          subtitle: Text(
                            editSizeOn
                                ? 'Sizes ENABLED (S, M, L, XL, Waist sizes)'
                                : 'Sizes DISABLED (Greyed out when adding products)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: editSizeOn ? Colors.green[800] : Colors.red[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: editSizeOn,
                          activeThumbColor: Colors.black,
                          onChanged: (val) {
                            setDialogState(() => editSizeOn = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (editImageUrl.isNotEmpty)
                            Container(
                              width: 60,
                              height: 50,
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
                                          initialRatio: CropAspectRatioOption.square1x1,
                                        );

                                        if (croppedBytes != null) {
                                          setDialogState(() => isUploading = true);
                                          try {
                                            final url = await admin.uploadImageBytes(
                                              croppedBytes,
                                              file.name,
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
                              label: Text(editImageUrl.isEmpty ? 'UPLOAD COVER' : 'CHANGE COVER', style: const TextStyle(fontSize: 11)),
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
                    final updated = Department(
                      id: dept.id,
                      name: editNameController.text.trim(),
                      slug: editNameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
                      description: editDescController.text.trim(),
                      imageUrl: editImageUrl,
                      order: dept.order,
                      isSizeApplicable: editSizeOn,
                    );
                    await admin.saveDepartment(updated);
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

  // Edit Category Dialog
  void _openEditCategoryModal(BuildContext context, AdminProvider admin, CatalogProvider catalog, CategoryItem cat) {
    final editNameController = TextEditingController(text: cat.name);
    String editDeptId = cat.departmentId;

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
              title: Text('EDIT CATEGORY: ${cat.name}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: editDeptId.isNotEmpty ? editDeptId : null,
                      dropdownColor: Colors.white,
                      style: GoogleFonts.inter(color: Colors.black),
                      decoration: const InputDecoration(labelText: 'Parent Segment'),
                      items: catalog.departments.map((d) {
                        return DropdownMenuItem(value: d.id, child: Text(d.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => editDeptId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: editNameController,
                      style: GoogleFonts.inter(color: Colors.black),
                      decoration: const InputDecoration(labelText: 'Category Name'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updated = CategoryItem(
                      id: cat.id,
                      name: editNameController.text.trim(),
                      slug: editNameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
                      departmentId: editDeptId,
                      order: cat.order,
                    );
                    await admin.saveCategory(updated);
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
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Text(
          'TAXONOMY & SIZES MANAGEMENT',
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
            // Help Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF000000), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF000000), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Help: Click EDIT on any existing Segment to toggle whether Sizes apply to it or edit details.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF333333)),
                    ),
                  ),
                ],
              ),
            ),

            // Segments Section
            Text(
              '1. SEGMENTS & SIZES TOGGLE',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF000000)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF000000), width: 2.0),
              ),
              child: Column(
                children: [
                  ...catalog.departments.map((d) {
                    final isMobile = MediaQuery.of(context).size.width < 750;

                    if (isMobile) {
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
                                Expanded(
                                  child: Text(d.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: d.isSizeApplicable ? const Color(0xFF000000) : const Color(0xFFE5E5E5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    d.isSizeApplicable ? 'SIZES ON' : 'SIZES OFF',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: d.isSizeApplicable ? Colors.white : const Color(0xFF666666),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              d.description.isNotEmpty ? d.description : 'No description',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                                  tooltip: 'Edit Segment',
                                  onPressed: () => _openEditDepartmentModal(context, admin, d),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Delete Segment',
                                  onPressed: () => admin.deleteDepartment(d.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        title: Row(
                          children: [
                            Text(d.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: d.isSizeApplicable ? const Color(0xFF000000) : const Color(0xFFE5E5E5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.isSizeApplicable ? 'SIZES ON' : 'SIZES OFF',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: d.isSizeApplicable ? Colors.white : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          d.description.isNotEmpty ? d.description : 'No description',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                              tooltip: 'Edit Segment',
                              onPressed: () => _openEditDepartmentModal(context, admin, d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Delete Segment',
                              onPressed: () => admin.deleteDepartment(d.id),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
                  const Divider(color: Color(0xFF000000), height: 32, thickness: 1),
                  TextFormField(
                    controller: _deptNameController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'New Segment Name (e.g. MENSWEAR)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deptDescController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Short Description'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Enable Sizes for this Segment (e.g. S, M, L, XL, Waist 28-38)',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
                    ),
                    subtitle: Text(
                      'Turn OFF for accessories, bags, or one-size items',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
                    ),
                    value: _isDeptSizeApplicable,
                    activeThumbColor: const Color(0xFF000000),
                    onChanged: (val) => setState(() => _isDeptSizeApplicable = val),
                  ),
                  const SizedBox(height: 16),

                  // Cover Image Upload Button & Preview
                  // Cover Image Upload Button & Preview (Responsive Layout)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = MediaQuery.of(context).size.width < 750;
                      final uploadBtn = OutlinedButton.icon(
                        onPressed: _isUploadingDeptImage ? null : _pickAndUploadDeptImage,
                        icon: _isUploadingDeptImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.cloud_upload_outlined, color: Colors.black),
                        label: Text(
                          _uploadedDeptImageUrl.isEmpty
                              ? 'UPLOAD SEGMENT COVER IMAGE'
                              : 'CHANGE COVER IMAGE',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black),
                        ),
                      );

                      if (_uploadedDeptImageUrl.isNotEmpty) {
                        final previewContainer = Container(
                          width: isMobile ? double.infinity : 80,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF000000)),
                            image: DecorationImage(
                              image: NetworkImage(_uploadedDeptImageUrl),
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
                    'Ratio 1:1 Square (Recommended: 800x800 px)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _addDepartment(admin),
                    child: const Text('ADD SEGMENT'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Categories Section
            Text(
              '2. CATEGORIES',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF000000)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF000000), width: 2.0),
              ),
              child: Column(
                children: [
                  ...catalog.categories.map((c) {
                    final isMobile = MediaQuery.of(context).size.width < 750;
                    final deptName = catalog.getDepartmentById(c.departmentId)?.name ?? 'Unassigned';

                    if (isMobile) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                            const SizedBox(height: 4),
                            Text('Segment: $deptName', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                                  tooltip: 'Edit Category',
                                  onPressed: () => _openEditCategoryModal(context, admin, catalog, c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Delete Category',
                                  onPressed: () => admin.deleteCategory(c.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        title: Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                        subtitle: Text('Segment: $deptName', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                              tooltip: 'Edit Category',
                              onPressed: () => _openEditCategoryModal(context, admin, catalog, c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Delete Category',
                              onPressed: () => admin.deleteCategory(c.id),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
                  const Divider(color: Color(0xFF000000), height: 32, thickness: 1),
                  DropdownButtonFormField<String>(
                    initialValue: _catDeptId.isNotEmpty ? _catDeptId : null,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Select Parent Segment'),
                    items: catalog.departments.map((d) {
                      return DropdownMenuItem(value: d.id, child: Text(d.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _catDeptId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _catNameController,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(labelText: 'Category Name (e.g. Jackets & Coats)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _addCategory(admin),
                    child: const Text('ADD CATEGORY'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
