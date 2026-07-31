import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/business_provider.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _checkoutWhatsApp(BuildContext context, CartProvider cart, BusinessProvider business) async {
    final message = cart.generateWhatsAppMessage();
    final waNum = business.settings.whatsAppNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final cleanWa = waNum.startsWith('+') ? waNum.substring(1) : waNum;
    
    final uri = Uri.parse('https://wa.me/$cleanWa?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp'), backgroundColor: Colors.red),
        );
      }
    }
  }

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Announcement/Header Banner
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
                    'Review your selected items and inquiry options',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666)),
                  ),
                  const Divider(color: Colors.black, height: 40, thickness: 1.5),

                  if (cart.items.isEmpty)
                    _buildEmptyCart(context)
                  else
                    isMobile
                        ? _buildMobileLayout(context, cart, groupedList, catalog, business)
                        : _buildDesktopLayout(context, cart, groupedList, catalog, business),
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
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cart Items List (Left Side)
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

        // Cart Summary Card (Right Side)
        Expanded(
          flex: 1,
          child: _buildSummaryCard(context, cart, business),
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
        _buildSummaryCard(context, cart, business),
      ],
    );
  }

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
          // Product Image
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
          // Product Details (Title, Table, Product Total)
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
                
                // Sizes Table
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1), // Size
                    1: FlexColumnWidth(2), // Qty Stepper
                    2: FlexColumnWidth(2), // Unit Price
                    3: FlexColumnWidth(2), // Total
                    4: FixedColumnWidth(40), // Delete button
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Table Header
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1.5)),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('Size', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666))),
                        ),
                        Text('Qty', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666)), textAlign: TextAlign.center),
                        Text('Unit Price', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666)), textAlign: TextAlign.center),
                        Text('Total', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF666666)), textAlign: TextAlign.center),
                        const SizedBox.shrink(),
                      ],
                    ),
                    // Table Rows for each size
                    ...groupedItem.sizes.map((item) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              item.size,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                          ),
                          _HZCartInlineQuantityStepper(
                            productId: item.productId,
                            size: item.size,
                            quantity: item.quantity,
                            cart: cart,
                          ),
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Color(0xFF888888)),
                            onPressed: () => cart.removeItem(item.productId, item.size),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                
                const SizedBox(height: 16),
                // Product Total Display
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
          // Product Image and Title Row
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
          
          // Table for sizes
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1), // Size
              1: FlexColumnWidth(2.5), // Qty Stepper
              2: FlexColumnWidth(2), // Total Price
              3: FixedColumnWidth(30), // Delete button
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1.5)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Size', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF666666))),
                  ),
                  Text('Qty', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF666666)), textAlign: TextAlign.center),
                  Text('Total', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF666666)), textAlign: TextAlign.center),
                  const SizedBox.shrink(),
                ],
              ),
              ...groupedItem.sizes.map((item) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        item.size,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                    ),
                    _HZCartInlineQuantityStepper(
                      productId: item.productId,
                      size: item.size,
                      quantity: item.quantity,
                      cart: cart,
                    ),
                    Text(
                      '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: Color(0xFF888888)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => cart.removeItem(item.productId, item.size),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          
          const SizedBox(height: 10),
          // Product Total Display
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

  Widget _buildSummaryCard(BuildContext context, CartProvider cart, BusinessProvider business) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INQUIRY SUMMARY',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Quantity', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
              Text('${cart.totalQuantity}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
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
              onPressed: () => _checkoutWhatsApp(context, cart, business),
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              label: Text(
                'ORDER ON WHATSAPP',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 13),
              ),
            ),
          ),
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

class _HZCartInlineQuantityStepper extends StatefulWidget {
  final String productId;
  final String size;
  final int quantity;
  final CartProvider cart;

  const _HZCartInlineQuantityStepper({
    required this.productId,
    required this.size,
    required this.quantity,
    required this.cart,
  });

  @override
  State<_HZCartInlineQuantityStepper> createState() => _HZCartInlineQuantityStepperState();
}

class _HZCartInlineQuantityStepperState extends State<_HZCartInlineQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _HZCartInlineQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity && !_focusNode.hasFocus) {
      _controller.text = widget.quantity.toString();
    }
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
    final val = int.tryParse(_controller.text);
    if (val != null && val >= 1) {
      if (val != widget.quantity) {
        widget.cart.updateQuantity(widget.productId, widget.size, val);
      }
    } else {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.remove, size: 14, color: Colors.black),
          onPressed: () {
            if (widget.quantity > 1) {
              widget.cart.updateQuantity(widget.productId, widget.size, widget.quantity - 1);
            }
          },
        ),
        SizedBox(
          width: 32,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _submitValue(),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const Icon(Icons.add, size: 14, color: Colors.black),
          onPressed: () {
            widget.cart.updateQuantity(widget.productId, widget.size, widget.quantity + 1);
          },
        ),
      ],
    );
  }
}
