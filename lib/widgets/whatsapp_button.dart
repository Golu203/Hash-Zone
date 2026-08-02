import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../providers/business_provider.dart';
import '../providers/catalog_provider.dart';
import 'customer_info_dialog.dart';

class WhatsAppInquiryButton extends StatelessWidget {
  final Product product;
  final bool isFullWidth;
  final String? selectedSize;
  /// When true, renders a compact single-line button for small card contexts
  final bool compact;

  const WhatsAppInquiryButton({
    super.key,
    required this.product,
    this.isFullWidth = true,
    this.selectedSize,
    this.compact = false,
  });

  Future<void> _launchWhatsApp(BuildContext context) async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);

    final result = await HZCustomerInfoDialog.show(context);
    if (result == null) return; // user cancelled

    final rawNumber = businessProvider.settings.whatsAppNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final cleanWa = rawNumber.startsWith('+') ? rawNumber.substring(1) : rawNumber;
    final dept = catalogProvider.getDepartmentById(product.departmentId)?.name ?? 'Apparel';
    final cat = catalogProvider.getCategoryById(product.categoryId)?.name ?? 'Clothing';
    final currentUrl = '${Uri.base.origin}/#/product/${product.slug}';

    final sizeInfo = (selectedSize != null && selectedSize!.isNotEmpty)
        ? '\n• Selected Size: $selectedSize'
        : '';

    final priceInfo = product.price.trim().isNotEmpty
        ? '\n• Price: ${product.price}'
        : '';

    final customerName = result['name'] ?? '';
    final customerPhone = result['phone'] ?? '';
    final customerNote = result['note'] ?? '';

    final detailsBuffer = StringBuffer();
    detailsBuffer.writeln('🛍️ *PRODUCT INQUIRY - HASH ZONE*');
    detailsBuffer.writeln('──────────────────');
    detailsBuffer.writeln('👤 *Customer Details*');
    detailsBuffer.writeln('   • Name: ${customerName.trim()}');
    if (customerPhone.trim().isNotEmpty) {
      detailsBuffer.writeln('   • Phone: ${customerPhone.trim()}');
    }
    if (customerNote.trim().isNotEmpty) {
      detailsBuffer.writeln('   • Note: ${customerNote.trim()}');
    }
    detailsBuffer.writeln('──────────────────');

    final message = '''
${detailsBuffer.toString()}Hello HASH ZONE,

I am interested in inquiring about this item from your store:

• Product Name: ${product.title}
• SKU CODE: "${product.sku}"$sizeInfo
• Segment: $dept
• Category: $cat$priceInfo
• URL: $currentUrl

Could you please provide availability and order details?
''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('https://wa.me/$cleanWa?text=$encodedMessage');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch WhatsApp. Number: ${businessProvider.settings.whatsAppNumber}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: () => _launchWhatsApp(context),
      icon: Icon(
        Icons.chat_outlined,
        color: Colors.white,
        size: compact ? 13 : 20,
      ),
      label: Text(
        compact ? 'WHATSAPP' : 'INQUIRE ON WHATSAPP',
        style: GoogleFonts.inter(
          fontSize: compact ? 10 : 14,
          fontWeight: FontWeight.bold,
          letterSpacing: compact ? 0.6 : 1.2,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 7)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        shadowColor: const Color(0x4425D366),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
