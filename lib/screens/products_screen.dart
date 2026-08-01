import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/catalog_provider.dart';
import '../widgets/footer.dart';
import '../widgets/navbar.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_loaders.dart';

import '../utils/seo_helper.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final products = catalog.filteredProducts;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Premium Wholesale Apparel & Garment Collection | HASH ZONE',
        description: 'Explore export quality bulk clothing collections from Tiruppur\'s leading garment factory. Premium Cotton T-Shirts, Polo shirts, hoodies, kids & mens clothing.',
        keywords: 'Wholesale Apparel, Bulk Clothing Supplier India, T-Shirt Manufacturer Tiruppur, Cotton Clothing Manufacturer, Export Quality Garments, Tiruppur, Tamil Nadu, India',
        path: '/products',
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Page Header Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 40 : 24,
                horizontal: isDesktop ? 32 : 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F8),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Column(
                children: [
                  Text(
                    catalog.onlyOffers ? 'EXCLUSIVE OFFERS' : 'CATALOG',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: isDesktop ? 3.0 : 2.0,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Filter & Search Controls Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
              child: isDesktop
                  ? Row(
                      children: [
                        const Spacer(),
                        SizedBox(
                          width: 280,
                          height: 42,
                          child: TextField(
                            onChanged: (val) => catalog.setSearchQuery(val),
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111111)),
                            decoration: InputDecoration(
                              hintText: 'Filter by keyword...',
                              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888)),
                              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF555555)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              suffixIcon: catalog.searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16, color: Color(0xFF555555)),
                                      onPressed: () => catalog.setSearchQuery(''),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SortOption>(
                              value: catalog.sortOption,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.sort, color: Color(0xFF333333)),
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111111)),
                              onChanged: (opt) {
                                if (opt != null) catalog.setSortOption(opt);
                              },
                              items: const [
                                DropdownMenuItem(value: SortOption.latest, child: Text('Sort: Latest')),
                                DropdownMenuItem(value: SortOption.priceLowToHigh, child: Text('Price: Low → High')),
                                DropdownMenuItem(value: SortOption.priceHighToLow, child: Text('Price: High → Low')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Row 1: Search bar + Filter button
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: TextField(
                                  onChanged: (val) => catalog.setSearchQuery(val),
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111111)),
                                  decoration: InputDecoration(
                                    hintText: 'Search products...',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888)),
                                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF555555)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                    suffixIcon: catalog.searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 16, color: Color(0xFF555555)),
                                            onPressed: () => catalog.setSearchQuery(''),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => _openMobileFilterBottomSheet(context),
                              icon: const Icon(Icons.filter_list, size: 18),
                              label: const Text('FILTERS'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Row 2: Sort dropdown full-width
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SortOption>(
                              isExpanded: true,
                              value: catalog.sortOption,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.sort, color: Color(0xFF333333)),
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111111)),
                              onChanged: (opt) {
                                if (opt != null) catalog.setSortOption(opt);
                              },
                              items: const [
                                DropdownMenuItem(value: SortOption.latest, child: Text('Sort: Latest')),
                                DropdownMenuItem(value: SortOption.priceLowToHigh, child: Text('Price: Low → High')),
                                DropdownMenuItem(value: SortOption.priceHighToLow, child: Text('Price: High → Low')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Active Filters Tags
            if (catalog.selectedDepartmentId.isNotEmpty || catalog.selectedCategoryId.isNotEmpty || catalog.searchQuery.isNotEmpty || catalog.onlyOffers)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Text('Active Filters: ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (catalog.selectedDepartmentId.isNotEmpty)
                              _filterChip(
                                label: 'Segment: ${catalog.getDepartmentById(catalog.selectedDepartmentId)?.name ?? ''}',
                                onRemove: () => catalog.setDepartmentFilter(''),
                              ),
                            if (catalog.selectedCategoryId.isNotEmpty)
                              _filterChip(
                                label: 'Category: ${catalog.getCategoryById(catalog.selectedCategoryId)?.name ?? ''}',
                                onRemove: () => catalog.setCategoryFilter(''),
                              ),
                            if (catalog.selectedSizeFilter.isNotEmpty)
                              _filterChip(
                                label: 'Size: ${catalog.selectedSizeFilter}',
                                onRemove: () => catalog.setSizeFilter(''),
                              ),
                            if (catalog.onlyOffers)
                              _filterChip(
                                label: 'Special Offers',
                                onRemove: () => catalog.toggleOffersOnly(false),
                              ),
                            if (catalog.searchQuery.isNotEmpty)
                              _filterChip(
                                label: 'Search: "${catalog.searchQuery}"',
                                onRemove: () => catalog.setSearchQuery(''),
                              ),
                            TextButton(
                              onPressed: () => catalog.clearFilters(),
                              child: Text('Clear All', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF000000), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Main Product Grid Layout
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Desktop Sidebar Filters (Width: 260)
                        SizedBox(
                          width: 260,
                          child: _buildDesktopSidebarFilter(context, catalog),
                        ),
                        const SizedBox(width: 36),
                        // Product Grid Area
                        Expanded(
                          child: _buildProductsGrid(context, catalog, products),
                        ),
                      ],
                    )
                  : _buildProductsGrid(context, catalog, products),
            ),

            const SizedBox(height: 80),
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context, CatalogProvider catalog, List<Product> products) {
    if (catalog.isLoading) {
      return const ProductSkeletonGrid(count: 6);
    }

    if (products.isEmpty) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Color(0xFF888888)),
            const SizedBox(height: 16),
            Text(
              'NO PRODUCTS FOUND',
              style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF111111)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try clearing your search query or selecting a different department filter.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => catalog.clearFilters(),
              child: const Text('RESET ALL FILTERS'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        // Determine number of columns based on available width
        final isMobile = availW < 500;
        final crossAxisCount = isMobile ? 2 : (availW < 800 ? 3 : 4);
        final spacing = isMobile ? 10.0 : 20.0;
        // Exact card width from grid math
        final cardWidth =
            (availW - spacing * (crossAxisCount - 1)) / crossAxisCount;
        // Image is 3:4 portrait + fixed info section height
        final infoH = isMobile ? 180.0 : 195.0;
        final cardHeight = cardWidth * (4 / 3) + infoH;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: cardHeight,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }

  Widget _buildDesktopSidebarFilter(BuildContext context, CatalogProvider catalog) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FILTERS',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: const Color(0xFF000000),
                ),
              ),
              if (catalog.selectedDepartmentId.isNotEmpty || catalog.selectedCategoryId.isNotEmpty)
                InkWell(
                  onTap: () => catalog.clearFilters(),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
                  ),
                ),
            ],
          ),
          const Divider(color: Color(0xFFE5E5E5), height: 24),

          // Segment List Filter
          Text(
            'SEGMENT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),
          _filterRadioTile(
            title: 'All Segments',
            isSelected: catalog.selectedDepartmentId.isEmpty,
            onTap: () => catalog.setDepartmentFilter(''),
          ),
          ...catalog.departments.map((d) => _filterRadioTile(
                title: d.name,
                isSelected: catalog.selectedDepartmentId == d.id,
                onTap: () => catalog.setDepartmentFilter(d.id),
              )),

          const Divider(color: Color(0xFFE5E5E5), height: 24),

          // Categories Filter (if department selected)
          if (catalog.selectedDepartmentId.isNotEmpty) ...[
            Text(
              'CATEGORY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 10),
            _filterRadioTile(
              title: 'All Categories',
              isSelected: catalog.selectedCategoryId.isEmpty,
              onTap: () => catalog.setCategoryFilter(''),
            ),
            ...catalog.getCategoriesForDepartment(catalog.selectedDepartmentId).map((c) => _filterRadioTile(
                  title: c.name,
                  isSelected: catalog.selectedCategoryId == c.id,
                  onTap: () => catalog.setCategoryFilter(c.id),
                )),
            const Divider(color: Color(0xFFE5E5E5), height: 24),
          ],

          // Size Filter Section
          if (catalog.allAvailableSizes.isNotEmpty) ...[
            Text(
              'SIZE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: catalog.selectedSizeFilter.isEmpty,
                  selectedColor: const Color(0xFF000000),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: catalog.selectedSizeFilter.isEmpty ? Colors.white : const Color(0xFF111111),
                  ),
                  onSelected: (_) => catalog.setSizeFilter(''),
                ),
                ...catalog.allAvailableSizes.map((size) {
                  final isSelected = catalog.selectedSizeFilter == size;
                  return ChoiceChip(
                    label: Text(size),
                    selected: isSelected,
                    selectedColor: const Color(0xFF000000),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : const Color(0xFF111111),
                    ),
                    onSelected: (_) => catalog.setSizeFilter(isSelected ? '' : size),
                  );
                }),
              ],
            ),
            const Divider(color: Color(0xFFE5E5E5), height: 24),
          ],

          // Offers Only Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Special Offers Only',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111111)),
            ),
            value: catalog.onlyOffers,
            activeThumbColor: const Color(0xFF000000),
            onChanged: (val) => catalog.toggleOffersOnly(val),
          ),
        ],
      ),
    );
  }

  Widget _filterRadioTile({required String title, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? const Color(0xFF000000) : const Color(0xFF888888),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF000000) : const Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMobileFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final catalog = Provider.of<CatalogProvider>(context);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('FILTERS', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    TextButton(
                      onPressed: () {
                        catalog.clearFilters();
                        Navigator.pop(context);
                      },
                      child: Text('RESET ALL', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  child: _buildDesktopSidebarFilter(context, catalog),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('APPLY FILTERS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
