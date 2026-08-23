import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';

/// HZBundleInfoWidget — replaces the old HZSizePriceTable.
/// Shows bundle configuration details: name, sizes, pieces/size,
/// total pieces per bundle, and price per bundle.
/// Falls back to legacy size/price table for products not yet migrated.
class HZBundleInfoWidget extends StatelessWidget {
  final Product product;
  final bool isSmall;

  const HZBundleInfoWidget({
    super.key,
    required this.product,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    if (product.hasBundle) {
      return _buildBundleView(product.bundle!);
    }
    // Fallback for products not yet migrated: show legacy size/price info
    return _buildLegacyFallback();
  }

  Widget _buildBundleView(ProductBundle b) {
    final labelStyle = GoogleFonts.inter(
      fontSize: isSmall ? 8.5 : 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: const Color(0xFF888888),
    );
    final valueStyle = GoogleFonts.inter(
      fontSize: isSmall ? 10 : 12,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF111111),
    );

    return Container(
      padding: EdgeInsets.all(isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bundle badge + name row
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 5 : 7,
                  vertical: isSmall ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BUNDLE',
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 7 : 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  b.bundleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 9 : 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Price per bundle — prominent
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                b.priceLabel,
                style: GoogleFonts.inter(
                  fontSize: isSmall ? 13 : 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ bundle',
                style: GoogleFonts.inter(
                  fontSize: isSmall ? 8 : 10,
                  color: const Color(0xFF888888),
                ),
              ),
            ],
          ),

          SizedBox(height: isSmall ? 4 : 6),

          // Stats row: total pieces + pieces per size
          Wrap(
            spacing: isSmall ? 6 : 10,
            runSpacing: 4,
            children: [
              _statChip(
                label: 'Total Pieces',
                value: '${b.totalPieces}',
                isSmall: isSmall,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              _statChip(
                label: 'Pcs / Size',
                value: '${b.piecesPerSize}',
                isSmall: isSmall,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
            ],
          ),

          SizedBox(height: isSmall ? 4 : 6),

          // Sizes breakdown
          Text('SIZES', style: labelStyle),
          const SizedBox(height: 3),
          Wrap(
            spacing: isSmall ? 4 : 6,
            runSpacing: 4,
            children: b.sizes.map((s) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 5 : 8,
                  vertical: isSmall ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 9 : 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required bool isSmall,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildLegacyFallback() {
    // Show a simple "Inquiry" or price text for non-migrated products
    final priceText = product.price.trim().isNotEmpty ? product.price : 'Inquiry';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        priceText,
        style: GoogleFonts.inter(
          fontSize: isSmall ? 12 : 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111111),
        ),
      ),
    );
  }
}

// Keep the old name as an alias for any files that still import HZSizePriceTable
// to prevent compilation errors during the transition.
// TODO: Remove after all call sites are updated.
typedef HZSizePriceTable = HZBundleInfoWidget;
