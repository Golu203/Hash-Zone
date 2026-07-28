import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/cloudinary_image_widget.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String _searchFilter = '';

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final filteredProducts = catalog.products.where((p) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return p.title.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Text(
          'PRODUCTS MANAGEMENT',
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
            // Top Controls Bar (Responsive Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 750;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        onChanged: (val) => setState(() => _searchFilter = val),
                        style: GoogleFonts.inter(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'Search products by title or SKU...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF000000)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/admin/products/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('ADD NEW PRODUCT'),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchFilter = val),
                          style: GoogleFonts.inter(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Search products by title or SKU...',
                            prefixIcon: Icon(Icons.search, color: Color(0xFF000000)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/admin/products/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('ADD NEW PRODUCT'),
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // Help Card with Bold Black Border
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
                      'Help: Click on "FEATURED" or "OFFER" chips to toggle item visibility in homepage sections.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF333333)),
                    ),
                  ),
                ],
              ),
            ),

            // Products Data Table Container with Bold Black Border
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF000000), width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: filteredProducts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          _searchFilter.isEmpty ? 'No products created yet. Click "+ ADD NEW PRODUCT" to get started.' : 'No products matching "$_searchFilter".',
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666)),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const Divider(color: Color(0xFF000000), height: 1, thickness: 1),
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        final deptName = catalog.getDepartmentById(p.departmentId)?.name ?? 'Segment';
                        final catName = catalog.getCategoryById(p.categoryId)?.name ?? 'Cat';
                        final sizesStr = p.availableSizes.isNotEmpty ? ' | Sizes: ${p.availableSizes.join(', ')}' : '';

                        final priceStr = p.isOffer && p.offerPrice != null && p.offerPrice! > 0
                            ? 'Offer: ${currencyFormatter.format(p.offerPrice!)}${p.price.isNotEmpty ? ' (Original: ${p.price})' : ''}'
                            : (p.price.isNotEmpty ? p.price : 'No price set');

                        return LayoutBuilder(
                          builder: (context, itemConstraints) {
                            final isItemMobile = MediaQuery.of(context).size.width < 750;

                            if (isItemMobile) {
                              // Beautiful Card Layout for Mobile
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Image Thumbnail
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFF000000), width: 1.0),
                                            color: const Color(0xFFF4F4F5),
                                          ),
                                          child: p.coverImage != null
                                              ? CloudinaryImageWidget(
                                                  imageSource: p.coverImage!,
                                                  width: 64,
                                                  height: 64,
                                                  targetWidth: 150,
                                                  borderRadius: BorderRadius.circular(10),
                                                )
                                              : const Icon(Icons.checkroom, color: Color(0xFF888888)),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.title,
                                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF000000)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'SKU: ${p.sku}',
                                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
                                              ),
                                              Text(
                                                '$deptName • $catName',
                                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF444444)),
                                              ),
                                              Text(
                                                priceStr,
                                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: p.isOffer ? const Color(0xFFD32F2F) : Colors.black),
                                              ),
                                              if (sizesStr.isNotEmpty)
                                                Text(
                                                  sizesStr.replaceFirst(' | ', ''),
                                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF555555)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Mobile Quick Action Bar (Chips and Buttons)
                                    Row(
                                      children: [
                                        ChoiceChip(
                                          label: Text('FEATURED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: p.isFeatured ? Colors.white : Colors.black)),
                                          selected: p.isFeatured,
                                          selectedColor: const Color(0xFF000000),
                                          onSelected: (_) => admin.toggleProductFeatured(p),
                                        ),
                                        const SizedBox(width: 8),
                                        ChoiceChip(
                                          label: Text('OFFER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: p.isOffer ? Colors.white : Colors.black)),
                                          selected: p.isOffer,
                                          selectedColor: const Color(0xFFD32F2F),
                                          onSelected: (_) => admin.toggleProductOffer(p),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF000000)),
                                          onPressed: () => context.go('/admin/products/edit/${p.id}'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _confirmDeleteProduct(context, admin, p),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Standard Desktop Table Row Layout
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF000000), width: 1.0),
                                    color: const Color(0xFFF4F4F5),
                                  ),
                                  child: p.coverImage != null
                                      ? CloudinaryImageWidget(
                                          imageSource: p.coverImage!,
                                          width: 56,
                                          height: 56,
                                          targetWidth: 150,
                                          borderRadius: BorderRadius.circular(10),
                                        )
                                      : const Icon(Icons.checkroom, color: Color(0xFF888888)),
                                ),
                                title: Text(
                                  p.title,
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF000000)),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'SKU: ${p.sku} | $deptName • $catName | $priceStr$sizesStr',
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF444444)),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ChoiceChip(
                                      label: Text('FEATURED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: p.isFeatured ? Colors.white : Colors.black)),
                                      selected: p.isFeatured,
                                      selectedColor: const Color(0xFF000000),
                                      onSelected: (_) => admin.toggleProductFeatured(p),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: Text('OFFER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: p.isOffer ? Colors.white : Colors.black)),
                                      selected: p.isOffer,
                                      selectedColor: const Color(0xFFD32F2F),
                                      onSelected: (_) => admin.toggleProductOffer(p),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF000000)),
                                      onPressed: () => context.go('/admin/products/edit/${p.id}'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteProduct(context, admin, p),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, AdminProvider admin, p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2.0),
        ),
        title: Text('Delete Product?', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${p.title}"?', style: GoogleFonts.inter(color: const Color(0xFF333333))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await admin.deleteProduct(p.id);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
