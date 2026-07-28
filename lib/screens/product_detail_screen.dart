import 'package:flutter/material.dart';
import 'dart:convert';
import '../utils/seo_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../providers/business_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/footer.dart';
import '../widgets/image_gallery.dart';
import '../widgets/navbar.dart';
import '../widgets/product_card.dart';
import '../widgets/whatsapp_button.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call store at $phoneNumber')),
      );
    }
  }

  void _shareProduct(BuildContext context, Product product) {
    final currentUrl = Uri.base.toString();
    Share.share(
      'Check out ${product.title} (SKU: ${product.sku}) on HASH ZONE Digital Catalog:\n$currentUrl',
      subject: 'HASH ZONE - ${product.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context);
    final business = Provider.of<BusinessProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    Product? product;
    try {
      product = catalog.products.firstWhere((p) => p.id == productId || p.slug == productId);
    } catch (_) {
      product = null;
    }

    if (product == null) {
      return Scaffold(
        appBar: const HZNavBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'PRODUCT NOT FOUND',
                style: GoogleFonts.cormorantGaramond(fontSize: 28, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/products'),
                child: const Text('RETURN TO CATALOG'),
              ),
            ],
          ),
        ),
      );
    }

    final categoryName = catalog.getCategoryById(product.categoryId)?.name ?? 'Premium Wear';
    final deptName = catalog.getDepartmentById(product.departmentId)?.name ?? 'Exclusive Collection';

    // Related Products (same category or department)
    final relatedProducts = catalog.products
        .where((p) => p.id != product!.id && (p.categoryId == product.categoryId || p.departmentId == product.departmentId))
        .take(4)
        .toList();

    // Dynamically calculate dynamic JSON-LD Product schema
    final cleanPrice = product.price.replaceAll(RegExp(r'[^\d]'), '');
    final schemaJson = {
      "@context": "https://schema.org/",
      "@type": "Product",
      "name": product.title,
      "image": product.coverImageUrl,
      "description": product.description.isNotEmpty 
          ? product.description 
          : "Buy export quality bulk garments and premium apparel from leading factory in Tiruppur, India.",
      "sku": product.sku,
      "brand": {
        "@type": "Brand",
        "name": "HASH ZONE"
      },
      "offers": {
        "@type": "Offer",
        "url": "https://www.hashzone.in/product/${product.slug}",
        "priceCurrency": "INR",
        "price": cleanPrice.isNotEmpty ? cleanPrice : "0",
        "availability": "https://schema.org/InStock",
        "itemCondition": "https://schema.org/NewCondition"
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: '${product!.title} - Wholesale Garment Manufacturer | HASH ZONE',
        description: product!.description.isNotEmpty && product!.description.length > 20
            ? (product!.description.length > 155 ? '${product!.description.substring(0, 152)}...' : product!.description)
            : 'Bulk purchase of ${product!.title}. Premium quality, custom design configurations by leading clothing factory in Tiruppur, Tamil Nadu, India.',
        keywords: '${product!.title}, ${product!.sku}, Custom Clothing Manufacturer, OEM Clothing Manufacturer, Wholesale Clothing Supplier, Tiruppur Garment Factory, Tiruppur, Tamil Nadu, India',
        path: '/product/${product!.slug}',
        imageUrl: product!.coverImageUrl,
        jsonLdSchema: json.encode(schemaJson),
      );
    });

    return Scaffold(
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Breadcrumbs Navigation
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 14,
              ),
              color: const Color(0xFF0F0F0F),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/'),
                      child: Text('HOME', style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                    ),
                    const Text('  /  ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                    InkWell(
                      onTap: () => context.go('/products'),
                      child: Text('CATALOG', style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                    ),
                    const Text('  /  ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                    Text(
                      deptName.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                    ),
                    const Text('  /  ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Product Main Layout
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: isDesktop ? 0 : 0,
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: HZProductImageGallery(images: product.images)),
                        const SizedBox(width: 50),
                        Expanded(flex: 4, child: _buildProductDetailsInfo(context, product, categoryName, deptName, business, currencyFormatter)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HZProductImageGallery(images: product.images),
                        const SizedBox(height: 24),
                        _buildProductDetailsInfo(context, product, categoryName, deptName, business, currencyFormatter),
                      ],
                    ),
            ),

            const SizedBox(height: 80),            // Related Products Section
            if (relatedProducts.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RELATED PIECES',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: isDesktop ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availW = constraints.maxWidth;
                        final isMobile = MediaQuery.of(context).size.width < 500;
                        final crossAxisCount = isMobile ? 2 : (availW < 800 ? 3 : 4);
                        final spacing = isMobile ? 10.0 : 20.0;
                        final cardWidth = (availW - spacing * (crossAxisCount - 1)) / crossAxisCount;
                        final infoH = isMobile ? 175.0 : 190.0;
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
                          itemCount: relatedProducts.length,
                          itemBuilder: (context, index) {
                            return ProductCard(product: relatedProducts[index]);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 80),
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailsInfo(
    BuildContext context,
    Product product,
    String categoryName,
    String deptName,
    BusinessProvider business,
    NumberFormat currencyFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Tag & SKU
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                '$deptName • $categoryName'.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            Text(
              'SKU: ${product.sku}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Product Title
        Text(
          product.title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: MediaQuery.of(context).size.width < 500 ? 28 : 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFF111111),
          ),
        ),

        const SizedBox(height: 12),

        // Price Display (With Offer Discount Strikethrough)
        if (product.isOffer && product.offerPrice != null && product.offerPrice! > 0)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencyFormatter.format(product.offerPrice!),
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD32F2F),
                ),
              ),
              if (product.price.trim().isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  product.price,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SPECIAL OFFER',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          )
        else if (product.price.trim().isNotEmpty)
          Text(
            product.price,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111111),
            ),
          )
        else
          const SizedBox.shrink(),

        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE5E5E5), height: 1),
        const SizedBox(height: 24),

        // Interactive Customer Size Selector (If sizes available for product)
        _ProductDetailInfoWidget(
          product: product,
          business: business,
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _makePhoneCall(context, business.settings.contactNumbers.isNotEmpty ? business.settings.contactNumbers.first : ''),
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('CALL STORE NOW'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black87),
              tooltip: 'Share Product',
              style: IconButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCCCCCC)),
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () => _shareProduct(context, product),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Product Description
        if (product.description.isNotEmpty) ...[
          Text(
            'DESCRIPTION',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.7,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Product Specifications Table
        if (product.specifications.isNotEmpty) ...[
          Text(
            'SPECIFICATIONS & DETAILS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              children: product.specifications.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666)),
                      ),
                      Text(
                        entry.value,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductDetailInfoWidget extends StatefulWidget {
  final Product product;
  final BusinessProvider business;

  const _ProductDetailInfoWidget({
    required this.product,
    required this.business,
  });

  @override
  State<_ProductDetailInfoWidget> createState() => _ProductDetailInfoWidgetState();
}

class _ProductDetailInfoWidgetState extends State<_ProductDetailInfoWidget> {
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    if (widget.product.availableSizes.isNotEmpty) {
      _selectedSize = widget.product.availableSizes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.availableSizes.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'SELECT SIZE:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: const Color(0xFF111111),
                ),
              ),
              if (_selectedSize != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '($_selectedSize)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.product.availableSizes.map((size) {
              final isSelected = size == _selectedSize;
              return InkWell(
                onTap: () => setState(() => _selectedSize = size),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF000000) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF000000) : const Color(0xFFCCCCCC),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    size,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF111111),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // WhatsApp Inquiry Button with Selected Size
        WhatsAppInquiryButton(
          product: widget.product,
          isFullWidth: true,
          selectedSize: _selectedSize,
        ),
      ],
    );
  }
}
