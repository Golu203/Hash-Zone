import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/payment_config_service.dart';
import '../../services/address_service.dart';
import '../../services/ocr_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_verification_service.dart';
import '../../models/order_model.dart';
import '../../models/payment_verification.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/payment_help_centre.dart';
import '../../widgets/smart_back_button.dart';

// ── CheckoutItem (single-product Buy Now) ─────────────────────────────────────
class CheckoutItem {
  final String productId;
  final String title;
  final String imageUrl;
  final String size;
  final double price;
  final int quantity;
  final String sku;

  const CheckoutItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.size,
    required this.price,
    required this.quantity,
    required this.sku,
  });

  double get lineTotal => price * quantity;
}

// ── CheckoutScreen ────────────────────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  final CheckoutItem? buyNowItem;

  const CheckoutScreen({super.key, this.buyNowItem});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _noteCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();
  final _cloudinary = CloudinaryService();

  Uint8List? _screenshotBytes;
  String? _screenshotFilename;
  bool _isValidatingOcr = false;
  bool _isUploading = false;
  bool _isSubmitting = false;
  String? _validationError;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  List<CheckoutItem> _getItems(CartProvider cart) {
    if (widget.buyNowItem != null) return [widget.buyNowItem!];
    return cart.items.map((i) => CheckoutItem(
      productId: i.productId,
      title: i.title,
      imageUrl: i.imageUrl,
      size: i.size,
      price: i.price,
      quantity: i.quantity,
      sku: i.sku,
    )).toList();
  }

  double _subtotal(List<CheckoutItem> items) =>
      items.fold(0.0, (sum, i) => sum + i.lineTotal);

  Future<void> _pickScreenshot() async {
    setState(() {
      _validationError = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final ext = file.name.split('.').last.toLowerCase();

    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      setState(() {
        _validationError = 'Please upload a payment screenshot in JPG, JPEG, PNG or WEBP format.';
        _screenshotBytes = null;
        _screenshotFilename = null;
      });
      return;
    }

    if (file.bytes == null) {
      setState(() {
        _validationError = 'The uploaded image is not clear enough. Please upload a clearer payment confirmation screenshot.';
        _screenshotBytes = null;
        _screenshotFilename = null;
      });
      return;
    }

    setState(() {
      _screenshotBytes = file.bytes;
      _screenshotFilename = file.name;
      _validationError = null;
    });
  }

  Future<void> _handlePaymentSubmission() async {
    if (_isSubmitting) return;

    final utr = _utrCtrl.text.trim();
    if (utr.isEmpty) {
      setState(() => _validationError = 'Please enter your 12-digit Transaction ID / UTR.');
      return;
    }
    if (_screenshotBytes == null || _screenshotFilename == null) {
      setState(() => _validationError = 'Please upload your payment confirmation screenshot.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isValidatingOcr = true;
      _validationError = null;
    });

    try {
      // ── STEP 1: OCR Validation ───────────────────────────────────────────
      final ocrResult = await OcrService.validateScreenshot(
        bytes: _screenshotBytes!,
        filename: _screenshotFilename!,
        enteredUtr: utr,
      );

      if (!ocrResult.isValid) {
        setState(() {
          _isSubmitting = false;
          _isValidatingOcr = false;
          _validationError = ocrResult.errorMessage ?? 'Validation failed. Please verify your screenshot and UTR.';
        });
        return;
      }

      // ── STEP 2: Upload screenshot to Cloudinary ──────────────────────────
      setState(() {
        _isValidatingOcr = false;
        _isUploading = true;
      });

      String uploadedUrl = '';
      try {
        final uploaded = await _cloudinary.uploadImage(
          bytes: _screenshotBytes!,
          filename: _screenshotFilename!,
          cloudName: 'um227ll2',
          uploadPreset: 'hashzone_products',
          folder: 'hashzone/payments',
        );
        uploadedUrl = uploaded.url;
      } catch (uploadErr) {
        debugPrint('[Checkout] Cloudinary upload failed: $uploadErr');
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Screenshot upload failed. Please check your internet and try again.',
                style: GoogleFonts.inter()),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ));
        }
        return;
      }

      // ── STEP 3: Read providers ───────────────────────────────────────────
      final cart = Provider.of<CartProvider>(context, listen: false);
      final auth = Provider.of<CustomerAuthProvider>(context, listen: false);
      final addrProvider = Provider.of<AddressProvider>(context, listen: false);
      final defaultAddr = addrProvider.defaultAddress;

      final checkoutItems = _getItems(cart);
      final subtotal = _subtotal(checkoutItems);

      final String orderId = 'HZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
      final String customerId = auth.firebaseUser?.uid ?? auth.profile?.uid ?? 'guest';
      final String customerName = (auth.profile?.displayName.isNotEmpty == true)
          ? auth.profile!.displayName
          : (defaultAddr?.name.isNotEmpty == true ? defaultAddr!.name : 'Customer');
      final String customerPhone = auth.profile?.phoneNumber.isNotEmpty == true
          ? auth.profile!.phoneNumber
          : (defaultAddr?.phone ?? '');
      final String customerEmail = auth.profile?.email ?? auth.firebaseUser?.email ?? '';

      debugPrint('[Checkout] Creating order $orderId for customer $customerId ($customerName)');

      final orderShippingAddr = OrderShippingAddress(
        doorNumber: defaultAddr?.doorNumber ?? '',
        road: defaultAddr?.road ?? '',
        area: defaultAddr?.area ?? '',
        city: defaultAddr?.city ?? '',
        landmark: defaultAddr?.landmark ?? '',
      );

      final orderItems = checkoutItems.map((item) => OrderProductItem(
        productId: item.productId,
        title: item.title,
        imageUrl: item.imageUrl,
        sku: item.sku,
        size: item.size,
        quantity: item.quantity,
        unitPrice: item.price,
        lineTotal: item.lineTotal,
      )).toList();

      final now = DateTime.now();

      final newOrder = CustomerOrder(
        id: orderId,
        customerId: customerId,
        customerName: customerName,
        phoneNumber: customerPhone,
        whatsAppNumber: customerPhone,
        email: customerEmail,
        orderDate: now,
        status: 'Order Received',
        shippingAddress: orderShippingAddr,
        customerNote: _noteCtrl.text.trim(),
        paymentInfo: OrderPaymentInfo(
          method: 'Bank Transfer',
          amountPaid: subtotal,
          utrNumber: utr,
          paymentStatus: 'Submitted',
          cloudinaryScreenshotUrl: uploadedUrl,
        ),
        items: orderItems,
        subtotal: subtotal,
        shippingCharge: 0.0,
        pendingAmount: 0.0,
        grandTotal: subtotal,
        timeline: [
          OrderTimelineStage(stageName: 'Order Received', isCompleted: true, timestamp: now),
          const OrderTimelineStage(stageName: 'Order Confirmed', isCompleted: false),
          const OrderTimelineStage(stageName: 'Dispatched', isCompleted: false),
        ],
      );

      // ── STEP 4: Write Order to Firestore ─────────────────────────────────
      try {
        await OrderService().createOrder(newOrder);
        debugPrint('[Checkout] Order $orderId saved to Firestore successfully.');
      } catch (firestoreErr) {
        debugPrint('[Checkout] Firestore order write failed: $firestoreErr');
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Order creation failed. Please check your connection and try again.',
                style: GoogleFonts.inter()),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ));
        }
        return;
      }

      // ── STEP 5: Write PaymentVerification to Firestore ───────────────────
      try {
        final pv = PaymentVerification(
          id: orderId,
          orderId: orderId,
          orderDate: now,
          customerName: customerName,
          phoneNumber: customerPhone,
          whatsAppNumber: customerPhone,
          paymentMethod: 'Bank Transfer',
          amountPaid: subtotal,
          utrNumber: utr,
          cloudinaryUrl: uploadedUrl,
          customerNote: _noteCtrl.text.trim(),
          shippingAddress: defaultAddr?.summary ?? '',
          orderStatus: 'Order Received',
          paymentStatus: 'Submitted',
          submittedTime: now,
          ocrStatus: 'OCR Verified',
        );
        await PaymentVerificationService().submitVerification(pv);
        debugPrint('[Checkout] PaymentVerification $orderId saved successfully.');
      } catch (pvErr) {
        // Non-fatal — order already created. Log and continue.
        debugPrint('[Checkout] PaymentVerification write failed (non-fatal): $pvErr');
      }

      // ── STEP 6: Clear cart ───────────────────────────────────────────────
      if (widget.buyNowItem == null) {
        try { cart.clearCart(); } catch (_) {}
      }

      setState(() {
        _isSubmitting = false;
        _isUploading = false;
      });

      // ── STEP 7: Success notification + redirect ──────────────────────────
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '✅ Payment submitted successfully! Your order has been received.\n'
            'Track your order from My Orders.',
            style: GoogleFonts.inter(height: 1.5),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 5),
        ));
        context.go('/my-orders');
      }

    } catch (e, stack) {
      debugPrint('[Checkout] Unexpected error in payment submission: $e\n$stack');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isValidatingOcr = false;
          _isUploading = false;
          _validationError = 'Something went wrong. Please try again or contact support.';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment submission failed. Please try again.',
              style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!', style: GoogleFonts.inter()),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<CustomerAuthProvider>();
    final addr = context.watch<AddressProvider>();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;
    final isMobile = w < 600;

    final items = _getItems(cart);
    if (items.isEmpty && widget.buyNowItem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/cart'));
      return const SizedBox.shrink();
    }

    final subtotal = _subtotal(items);
    final defaultAddr = addr.defaultAddress;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Page header
            Container(
              width: double.infinity,
              color: const Color(0xFFF9F9F9),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 64, vertical: 24),
              child: Row(
                children: [
                  const HZSmartBackButton(fallbackRoute: '/cart', label: null),
                  const SizedBox(width: 8),
                  Text('Checkout', style: GoogleFonts.cormorantGaramond(fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 64, vertical: 32),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: address + note + payment cards + help centre + payment form
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildAddressSection(context, auth, addr, defaultAddr),
                              const SizedBox(height: 24),
                              _buildCustomerNote(),
                              const SizedBox(height: 24),
                              _buildPaymentSection(),
                              const SizedBox(height: 24),
                              const PaymentHelpCentre(),
                              const SizedBox(height: 24),
                              _buildPaymentSubmissionForm(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right column: order summary
                        SizedBox(
                          width: 380,
                          child: Column(
                            children: [
                              _buildOrderSummary(items, subtotal),
                              const SizedBox(height: 24),
                              _buildShippingNotice(),
                              const SizedBox(height: 16),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildOrderSummary(items, subtotal),
                        const SizedBox(height: 20),
                        _buildAddressSection(context, auth, addr, defaultAddr),
                        const SizedBox(height: 20),
                        _buildCustomerNote(),
                        const SizedBox(height: 20),
                        _buildPaymentSection(),
                        const SizedBox(height: 20),
                        const PaymentHelpCentre(),
                        const SizedBox(height: 20),
                        _buildPaymentSubmissionForm(),
                        const SizedBox(height: 20),
                        _buildShippingNotice(),
                        const SizedBox(height: 16),
                        _buildSubmitButton(),
                      ],
                    ),
            ),
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  // ── Order Summary ─────────────────────────────────────────────────────────
  Widget _buildOrderSummary(List<CheckoutItem> items, double subtotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEEEEE)),
          ...items.map((item) => _orderItemRow(item)),
          const Divider(color: Color(0xFFEEEEEE), height: 28),
          _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}', bold: false),
          const SizedBox(height: 8),
          _summaryRow('Shipping', 'Calculated separately', bold: false, valueColor: Colors.black45),
          const Divider(color: Color(0xFFEEEEEE), height: 20),
          _summaryRow('Grand Total', '₹${subtotal.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _orderItemRow(CheckoutItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58, height: 58,
                color: const Color(0xFFF0F0F0),
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Size: ${item.size}', style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                if (item.sku.isNotEmpty)
                  Text('SKU: ${item.sku}', style: GoogleFonts.inter(fontSize: 10, color: Colors.black38)),
                Text('Qty: ${item.quantity}', style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${item.lineTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('₹${item.price.toStringAsFixed(0)} each', style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  // ── Shipping Address Section ──────────────────────────────────────────────
  Widget _buildAddressSection(BuildContext context, CustomerAuthProvider auth, AddressProvider addr, CustomerAddress2? defaultAddr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Shipping Address', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/addresses'),
                child: Text('Manage', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (defaultAddr == null)
            GestureDetector(
              onTap: () => context.go('/addresses'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('No address saved. Tap to add one.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF57C00)))),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      defaultAddr.summary,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Customer Note ─────────────────────────────────────────────────────────
  Widget _buildCustomerNote() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Notes', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Optional — saved with your order.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Add any special instructions for this order.',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black38),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment Section (Firestore-driven with UPI Card & Bank Card) ────────
  Widget _buildPaymentSection() {
    return StreamBuilder<PaymentConfig>(
      stream: PaymentConfigService().streamConfig(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _paymentSkeleton();
        }
        final config = snap.data ?? const PaymentConfig();
        if (!config.isConfigured || !config.hasBankDetails) {
          return _paymentPlaceholder();
        }
        return _paymentDetails(config);
      },
    );
  }

  Widget _paymentSkeleton() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEEEEEE)), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black))),
        ],
      ),
    );
  }

  Widget _paymentPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, size: 40, color: Colors.black38),
          const SizedBox(height: 14),
          Text(
            'Payment Information',
            style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment information is currently being configured.\nPlease contact support if you need assistance.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _paymentDetails(PaymentConfig config) {
    return Column(
      children: [
        // Bank Transfer Details Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.black, size: 20),
                  const SizedBox(width: 10),
                  Text('Bank Transfer Details', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFEEEEEE)),
              _copyableBankRow('Account Name', config.accountName),
              _copyableBankRow('Bank Name', config.bankName),
              _copyableBankRow('Account Number', config.accountNumber, isCopyable: true),
              _copyableBankRow('IFSC Code', config.ifscCode, isCopyable: true),
              if (config.branchName.isNotEmpty)
                _copyableBankRow('Branch', config.branchName),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment Instructions
        if (config.paymentInstructions.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Text(
              config.paymentInstructions,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _copyableBankRow(String label, String value, {bool isCopyable = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: Colors.black54),
              tooltip: 'Copy $label',
              onPressed: () => _copyToClipboard(value, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // ── Payment Submission Form (UTR + Screenshot + Browser OCR) ────────────
  Widget _buildPaymentSubmissionForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submit Payment Confirmation', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Enter your 12-digit Transaction ID / UTR and upload your payment screenshot.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 16),

          // Validation Error Banner
          if (_validationError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFD32F2F), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // UTR Input
          TextField(
            controller: _utrCtrl,
            decoration: InputDecoration(
              labelText: 'Transaction ID / UTR Number *',
              hintText: 'e.g. 421839401284',
              labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              prefixIcon: const Icon(Icons.numbers, size: 18, color: Colors.black54),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          // Screenshot File Picker
          OutlinedButton.icon(
            onPressed: _pickScreenshot,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.image_search, size: 18),
            label: Text(
              _screenshotFilename != null ? 'CHANGE SCREENSHOT (${_screenshotFilename!})' : 'UPLOAD PAYMENT SCREENSHOT (JPG, PNG, WEBP)',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),

          if (_screenshotFilename != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Selected: $_screenshotFilename',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Shipping Notice ───────────────────────────────────────────────────────
  Widget _buildShippingNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD32F2F), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Shipping charges are calculated separately based on your delivery location, order quantity and courier service. The final shipping cost will be communicated to you via WhatsApp before dispatch.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD32F2F), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Place Order / Submit Button ───────────────────────────────────────────
  Widget _buildSubmitButton() {
    final isProcessing = _isValidatingOcr || _isUploading;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _handlePaymentSubmission,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black38,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))),
                  const SizedBox(width: 12),
                  Text(
                    _isValidatingOcr ? 'VERIFYING OCR...' : 'UPLOADING TO CLOUDINARY...',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 10),
                  Text('SUBMIT PAYMENT & COMPLETE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                ],
              ),
      ),
    );
  }
}
