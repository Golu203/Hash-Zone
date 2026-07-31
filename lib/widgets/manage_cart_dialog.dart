import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'product_action_dialog.dart';

class HZManageCartDialog extends StatefulWidget {
  final Product product;
  final BuildContext parentContext;

  const HZManageCartDialog({
    super.key,
    required this.product,
    required this.parentContext,
  });

  static Future<void> show(BuildContext context, {required Product product}) {
    return showDialog(
      context: context,
      builder: (dialogContext) => HZManageCartDialog(
        product: product,
        parentContext: context,
      ),
    );
  }

  @override
  State<HZManageCartDialog> createState() => _HZManageCartDialogState();
}

class _HZManageCartDialogState extends State<HZManageCartDialog> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitValue();
    }
  }

  void _submitValue() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final totalQty = cart.getProductTotalQuantity(widget.product.id);
    final val = int.tryParse(_controller.text);
    if (val != null) {
      if (val != totalQty) {
        cart.updateProductTotalQuantity(widget.product, val);
      }
    } else {
      _controller.text = totalQty.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final totalQty = cart.getProductTotalQuantity(widget.product.id);

    if (!_focusNode.hasFocus) {
      _controller.text = totalQty.toString();
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MANAGE CART',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(color: Color(0xFFE5E5E5), height: 24),

            // Product Details
            Row(
              children: [
                if (widget.product.coverImageUrl.isNotEmpty)
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                      image: DecorationImage(
                        image: NetworkImage(widget.product.coverImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${widget.product.sku}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Option 1: Update Existing Quantity
            Text(
              'UPDATE EXISTING QUANTITY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCCCCCC)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20, color: Colors.black),
                    onPressed: () {
                      if (totalQty > 0) {
                        cart.updateProductTotalQuantity(widget.product, totalQty - 1);
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitValue(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20, color: Colors.black),
                    onPressed: () {
                      cart.updateProductTotalQuantity(widget.product, totalQty + 1);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Option 2: Add Another Size
            Text(
              'OR ADD ANOTHER SIZE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close this Manage Cart popup
                  HZProductActionDialog.show(
                    widget.parentContext,
                    product: widget.product,
                    isWhatsApp: false,
                  ); // Open the existing Add to Cart popup
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                label: Text(
                  'ADD ANOTHER SIZE',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'DONE',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
