import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/business_provider.dart';
import '../providers/customer_auth_provider.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/smart_back_button.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showClearCartConfirmation(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'CLEAR SHOPPING CART',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: GoogleFonts.inter(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.inter(color: const Color(0xFF666666), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
            child: Text('CLEAR CART', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final catalog = Provider.of<CatalogProvider>(context);
    final business = Provider.of<BusinessProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 800;

    // Group items by product ID
    final groupedItems = <String, GroupedCartItem>{};
    for (var item in cart.items) {
      if (!groupedItems.containsKey(item.productId)) {
        groupedItems[item.productId] = GroupedCartItem(
          productId: item.productId,
          title: item.title,
          imageUrl: item.imageUrl,
          productUrl: item.productUrl,
          sizes: [],
        );
      }
      groupedItems[item.productId]!.sizes.add(item);
    }
    final groupedList = groupedItems.values.toList();

    // Legacy multiples-of-5 check (only for non-bundle items)
    final hasInvalidLegacyQty = cart.items.any((item) => !item.isBundleItem && item.quantity % 5 != 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: MediaQuery.of(context).size.width < 1150 ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (business.settings.announcementText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.black,
                child: Text(
                  business.settings.announcementText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

            Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HZSmartBackButton(fallbackRoute: '/products'),
                  const SizedBox(height: 12),
                  Text(
                    'YOUR SHOPPING CART',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review your selected items before checkout',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666)),
                  ),
                  const Divider(color: Colors.black, height: 40, thickness: 1.5),

                  if (cart.items.isEmpty)
                    _buildEmptyCart(context)
                  else
                    isMobile
                        ? _buildMobileLayout(context, cart, groupedList, catalog, business, hasInvalidLegacyQty)
                        : _buildDesktopLayout(context, cart, groupedList, catalog, business, hasInvalidLegacyQty),
                ],
              ),
            ),
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 72, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 20),
            Text(
              'Your shopping cart is empty.',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'CONTINUE SHOPPING',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    CartProvider cart,
    List<GroupedCartItem> groupedList,
    CatalogProvider catalog,
    BusinessProvider business,
    bool hasInvalidLegacyQty,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  return _buildGroupedCartCard(context, groupedList[index], cart, catalog);
                },
              ),
              const Divider(color: Colors.black, height: 40, thickness: 1.0),
              TextButton.icon(
                onPressed: () => _showClearCartConfirmation(context, cart),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  'CLEAR SHOPPING CART',
                  style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 1,
          child: _buildSummaryCard(context, cart, business, hasInvalidLegacyQty),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    CartProvider cart,
    List<GroupedCartItem> groupedList,
    CatalogProvider catalog,
    BusinessProvider business,
    bool hasInvalidLegacyQty,
  ) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groupedList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildGroupedMobileCartCard(context, groupedList[index], cart, catalog);
          },
        ),
        const Divider(color: Colors.black, height: 40, thickness: 1.0),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showClearCartConfirmation(context, cart),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: Text(
              'CLEAR SHOPPING CART',
              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildSummaryCard(context, cart, business, hasInvalidLegacyQty),
      ],
    );
  }

  // ── Desktop Grouped Cart Card ──────────────────────────────────────────────
  Widget _buildGroupedCartCard(
    BuildContext context,
    GroupedCartItem groupedItem,
    CartProvider cart,
    CatalogProvider catalog,
  ) {
    final product = catalog.products.firstWhere(
      (p) => p.id == groupedItem.productId,
      orElse: () => catalog.products.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 106,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E5E5)),
              image: DecorationImage(
                image: NetworkImage(groupedItem.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupedItem.title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (product.sku.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
                  ),
                ],
                const SizedBox(height: 12),

                // Bundle rows or legacy size table
                if (groupedItem.sizes.isNotEmpty && groupedItem.sizes.first.isBundleItem)
                  _buildBundleCartRows(context, groupedItem.sizes, cart, isMobile: false)
                else
                  _buildLegacySizeTable(context, groupedItem.sizes, cart, isMobile: false),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    Text(
                      'Product Total: ₹${groupedItem.total.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Grouped Cart Card ───────────────────────────────────────────────
  Widget _buildGroupedMobileCartCard(
    BuildContext context,
    GroupedCartItem groupedItem,
    CartProvider cart,
    CatalogProvider catalog,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: DecorationImage(
                    image: NetworkImage(groupedItem.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  groupedItem.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bundle rows or legacy table
          if (groupedItem.sizes.isNotEmpty && groupedItem.sizes.first.isBundleItem)
            _buildBundleCartRows(context, groupedItem.sizes, cart, isMobile: true)
          else
            _buildLegacySizeTable(context, groupedItem.sizes, cart, isMobile: true),

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Product Total: ₹${groupedItem.total.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bundle cart rows ───────────────────────────────────────────────────────
  Widget _buildBundleCartRows(
    BuildContext context,
    List<CartItem> items,
    CartProvider cart, {
    required bool isMobile,
  }) {
    return Column(
      children: items.map((item) {
        final totalPcs = item.totalPieces;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.bundleName ?? 'Bundle',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 11 : 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.bundleSizes?.join(', ') ?? '',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 10 : 11,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF888888)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => cart.removeItem(item.productId, item.size),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HZCartInlineQuantityStepper(
                      productId: item.productId,
                      size: item.size,
                      quantity: item.quantity,
                      cart: cart,
                      step: 1,
                      minValue: 1,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}/bundle',
                          style: GoogleFonts.inter(
                              fontSize: isMobile ? 10 : 11, color: const Color(0xFF555555)),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        Text(
                          '$totalPcs pcs total',
                          style: GoogleFonts.inter(
                              fontSize: isMobile ? 9 : 10, color: const Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Legacy size table ──────────────────────────────────────────────────────
  Widget _buildLegacySizeTable(
    BuildContext context,
    List<CartItem> items,
    CartProvider cart, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: isMobile
              ? const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(2),
                  3: FixedColumnWidth(30),
                }
              : const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FixedColumnWidth(40),
                },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1.5))),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('Size',
                      style: GoogleFonts.inter(
                          fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666))),
                ),
                Text('Qty',
                    style: GoogleFonts.inter(
                        fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666)),
                    textAlign: TextAlign.center),
                if (!isMobile)
                  Text('Unit Price',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666)),
                      textAlign: TextAlign.center),
                Text('Total',
                    style: GoogleFonts.inter(
                        fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666)),
                    textAlign: TextAlign.center),
                const SizedBox.shrink(),
              ],
            ),
            ...items.map((item) {
              return TableRow(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
                    child: Text(item.size,
                        style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600, color: Colors.black)),
                  ),
                  _HZCartInlineQuantityStepper(
                    productId: item.productId,
                    size: item.size,
                    quantity: item.quantity,
                    cart: cart,
                  ),
                  if (!isMobile)
                    Text('₹${item.price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                  Text('₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center),
                  IconButton(
                    icon: Icon(Icons.close, size: isMobile ? 14 : 16, color: const Color(0xFF888888)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => cart.removeItem(item.productId, item.size),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Wholesale: orders in multiples of 5 pieces.',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        if (items.any((item) => item.quantity % 5 != 0)) ...[
          const SizedBox(height: 4),
          Text(
            'Fix quantities to multiples of 5 before checkout.',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
          ),
        ],
      ],
    );
  }

  // ── Summary Card ───────────────────────────────────────────────────────────
  Widget _buildSummaryCard(
    BuildContext context,
    CartProvider cart,
    BusinessProvider business,
    bool hasInvalidLegacyQty,
  ) {
    final totalBundles = cart.items.where((i) => i.isBundleItem).fold<int>(0, (s, i) => s + i.quantity);
    final totalPieces = cart.items.fold<int>(0, (s, i) => s + i.totalPieces);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER SUMMARY',
            style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Products', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
              Text('${cart.items.length}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          if (totalBundles > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Bundles', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
                Text('$totalBundles', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pieces', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
                Text('$totalPieces', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Quantity', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
                Text('${cart.totalQuantity}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ],
          const Divider(height: 24, color: Color(0xFFE5E5E5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAND TOTAL', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              Text(
                '₹${cart.grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: hasInvalidLegacyQty
                  ? null
                  : () {
                      final auth = Provider.of<CustomerAuthProvider>(context, listen: false);
                      if (!auth.isAuthenticated) {
                        if (auth.needsOnboarding) {
                          context.go('/onboarding?redirect=${Uri.encodeComponent('/checkout')}');
                        } else {
                          context.go('/login?redirect=${Uri.encodeComponent('/checkout')}');
                        }
                      } else {
                        context.go('/checkout');
                      }
                    },
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              label: Text(
                'PROCEED TO CHECKOUT',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 13),
              ),
            ),
          ),
          if (hasInvalidLegacyQty) ...[
            const SizedBox(height: 12),
            Text(
              '⚠️ Some items have invalid quantities. Please fix quantities to multiples of 5.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GroupedCartItem {
  final String productId;
  final String title;
  final String imageUrl;
  final String productUrl;
  final List<CartItem> sizes;

  GroupedCartItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.productUrl,
    required this.sizes,
  });

  double get total {
    return sizes.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }
}

class _HZCartInlineQuantityStepper extends StatelessWidget {
  final String productId;
  final String size;
  final int quantity;
  final CartProvider cart;
  final int step;
  final int minValue;

  const _HZCartInlineQuantityStepper({
    required this.productId,
    required this.size,
    required this.quantity,
    required this.cart,
    this.step = 5,
    this.minValue = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HZQuantityStepper(
        initialValue: quantity,
        isSmall: true,
        height: 28,
        step: step,
        minValue: minValue,
        showNote: false,
        onChanged: (newQty, isValid) {
          if (isValid) {
            cart.updateQuantity(productId, size, newQty);
          }
        },
      ),
    );
  }
}
