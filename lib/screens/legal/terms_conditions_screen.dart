import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';
import '../../utils/seo_helper.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1150;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Terms & Conditions | HASH ZONE Wholesale Garments',
        description: 'Terms and conditions governing the purchase of wholesale clothing bundles, payments, logistics, and services on HASH ZONE (Sree Meenakshi Textiles, Tiruppur).',
        keywords: 'HashZone Terms and Conditions, Wholesale Garment Terms, Tiruppur Clothing Manufacturer Terms, Bundle Policy',
        path: '/terms',
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: isDesktop ? 50 : 36,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HZSmartBackButton(fallbackRoute: '/', color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'TERMS & CONDITIONS',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 40 : 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HASH ZONE · SREE MEENAKSHI TEXTILES (SMT), TIRUPPUR',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 13 : 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last Updated: August 23, 2026',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFB0B0B0),
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20,
                vertical: isDesktop ? 48 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNoticeBox(),
                      const SizedBox(height: 36),

                      _sectionTitle('1. INTRODUCTION'),
                      _paragraph(
                        'Welcome to HASH ZONE ("Website", "Platform", "we", "us", or "our"), operated by Sree Meenakshi Textiles (SMT), having its manufacturing operations situated at Tiruppur, Tamil Nadu, India. These Terms & Conditions ("Terms") govern your access to and use of our website, mobile interface, catalog browsing, wholesale product inquiries, account registration, bundle purchases, payment submissions, and post-order fulfillment services.',
                      ),

                      _sectionTitle('2. ACCEPTANCE OF TERMS'),
                      _paragraph(
                        'By accessing, registering an account, browsing our wholesale catalog, or purchasing wholesale bundles on this Website, you acknowledge that you have read, understood, and unconditionally agree to be bound by these Terms, together with our Privacy Policy, Refund & Cancellation Policy, and Shipping & Delivery Policy. If you do not agree to these Terms, you must immediately discontinue use of the Website.',
                      ),

                      _sectionTitle('3. ELIGIBILITY & CUSTOMER ACCOUNT'),
                      _paragraph(
                        'Our services and wholesale catalog are primarily intended for commercial buyers, retail store owners, distributors, reselling businesses, and individuals of legal age (at least 18 years under Indian law) capable of forming legally binding contracts under the Indian Contract Act, 1872. You agree to provide true, accurate, current, and complete details during customer onboarding and maintain the confidentiality of your account credentials.',
                      ),

                      _sectionTitle('4. WHOLESALE BUSINESS MODEL & BUNDLE PURCHASES'),
                      _paragraph(
                        'HASH ZONE operates on a wholesale garment manufacturer-direct model. Products on our platform are sold in PRE-CONFIGURED WHOLESALE BUNDLES. Each product bundle consists of:',
                      ),
                      _bulletPoint('Defined Size Assortment (e.g., S, M, L, XL, XXL, or Free Size as specified).'),
                      _bulletPoint('Defined Pieces Per Size (e.g., 5, 10, or 25 pieces per size category).'),
                      _bulletPoint('Total Fixed Number of Pieces per Bundle (e.g., 15, 20, 40, or 100 pieces per bundle unit).'),
                      _bulletPoint('Single Bundle Price covering the complete assortment of garments in that bundle.'),
                      _paragraph(
                        'Customers purchase complete bundles. Unless explicitly configured by HASH ZONE on a specific product listing, individual single-piece retail purchases are not supported.',
                      ),

                      _sectionTitle('5. PRODUCT INFORMATION & SPECIFICATIONS'),
                      _paragraph(
                        'We manufacture apparel in Tiruppur using quality fabrics (including cotton, blended fleece, single jersey, dry-fit, and rib knits). We strive to display product images, fabric textures, colors, and styling as accurately as possible. However, due to variances in digital screen displays, lighting conditions during photography, and manufacturing dye lots, minor color variations may occur and do not constitute a defect.',
                      ),

                      _sectionTitle('6. PRICING & BUNDLE RATES'),
                      _paragraph(
                        'All prices displayed on the Website are in Indian Rupees (INR / ₹) and represent the price for ONE COMPLETE BUNDLE unit (or wholesale order volume selected). Prices are subject to revision without prior notice based on raw yarn, fabric milling, and production cost fluctuations; however, confirmed orders with verified payment will be honored at the price applicable at the time of checkout.',
                      ),

                      _sectionTitle('7. ORDER PLACEMENT & CONFIRMATION'),
                      _paragraph(
                        'Placing an order on the Website constitutes a commercial offer to purchase wholesale merchandise. An order is deemed officially confirmed ONLY AFTER our administrative team verifies receipt of full payment via our Bank Transfer / UPI verification procedure. Upon verification, the order status in "My Account -> My Orders" will update to "Confirmed".',
                      ),

                      _sectionTitle('8. ORDER REJECTION & CANCELLATION BY HASHZONE'),
                      _paragraph(
                        'HASH ZONE reserves the right to reject, suspend, or cancel any order in whole or in part due to unforeseen fabric/stock shortages, manufacturing delays, payment verification discrepancies, unserviceable shipping destinations, or suspicion of fraudulent activity. In the event of an order rejection where full payment was received, a full refund will be processed in accordance with our Refund Policy.',
                      ),

                      _sectionTitle('9. CUSTOMER ORDER CANCELLATIONS'),
                      _paragraph(
                        'Because wholesale garments are batched, cut, packed, and dispatched rapidly, cancellation requests must be submitted before parcel dispatch. Once an order has been handed over to our logistics or courier partner and an AWB tracking number has been generated, order cancellation is no longer possible.',
                      ),

                      _sectionTitle('10. PAYMENT METHODS & BANK TRANSFER TERMS'),
                      _paragraph(
                        'To maintain competitive wholesale pricing without intermediary payment gateway surcharge deductions, payments on HASH ZONE are accepted primarily through Direct Bank Transfer (NEFT / RTGS / IMPS / NetBanking) and Official Business UPI. Customers must transfer the exact payable amount displayed at checkout to the official bank account of SREE MEENAKSHI TEXTILES specified in the checkout instructions.',
                      ),

                      _sectionTitle('11. PAYMENT VERIFICATION & UTR REFERENCE'),
                      _paragraph(
                        'Following bank transfer, the customer is required to enter the 12-digit Unique Transaction Reference (UTR / Bank Transaction ID) and optionally upload the payment screenshot proof in the Website checkout interface. Payment confirmation is determined by our administrative verification team cross-referencing bank credits. The upload of a screenshot alone does not constitute automatic settlement until administrative verification is complete.',
                      ),

                      _sectionTitle('12. CASH ON DELIVERY (COD)'),
                      _paragraph(
                        'Cash on Delivery (COD) is currently disabled for online wholesale bundle checkout. All online orders require pre-payment verification. Inquiries regarding credit terms or cash collections for large-scale enterprise consignments are handled offline via authorized management.',
                      ),

                      _sectionTitle('13. SHIPPING CHARGES & FREIGHT'),
                      _paragraph(
                        'Wholesale garment shipments vary considerably in volumetric weight and destination distances across India. Shipping charges are calculated based on destination PIN code, package weight, volumetric parcel size, and selected courier partner. Shipping charges and logistics arrangements are coordinated directly with the customer prior to or upon dispatch.',
                      ),

                      _sectionTitle('14. DELIVERY, TRANSIT & COURIER PARTNERS'),
                      _paragraph(
                        'Shipments are dispatched via reputed surface transport and courier carriers (including VRL Logistics, Professional Couriers, Delhivery, DTDC, India Post, or customer-preferred transport agencies operating out of Tiruppur). Estimated transit timelines typically range from 3 to 7 business days depending on destination geography. Delivery timelines are estimates and subject to regional courier operations and transit conditions.',
                      ),

                      _sectionTitle('15. INCORRECT ADDRESS & FAILED DELIVERY (RTO)'),
                      _paragraph(
                        'Customers are strictly responsible for providing accurate, complete delivery address details including Door/Building Number, Street/Road, Area/Locality, City, State, Landmark, and 6-digit PIN Code. If a consignment is returned to our Tiruppur facility (Return to Origin - RTO) due to incorrect address, customer unavailability, or refusal to accept delivery, additional re-dispatch freight costs will be payable by the customer.',
                      ),

                      _sectionTitle('16. DAMAGED, DEFECTIVE OR WRONG PRODUCTS'),
                      _paragraph(
                        'In the rare event of manufacturing defects, parcel transit damage, or quantity discrepancies, the customer must notify HASH ZONE Support within 48 hours of delivery along with photographic or video proof of unboxing. Validated claims will be promptly resolved through replacement, credit note, or refund in accordance with our Refund & Cancellation Policy.',
                      ),

                      _sectionTitle('17. REFUND PROCESSING TIMELINE'),
                      _paragraph(
                        'Eligible refunds approved by HASH ZONE management will generally be processed within 7 working days to the customer\'s verified source bank account. The exact time required for funds to credit depends on the customer\'s banking institution.',
                      ),

                      _sectionTitle('18. TAX INVOICES & SYSTEM RECEIPTS'),
                      _paragraph(
                        'System-generated receipts are made available immediately upon order placement. Official GST Tax Invoices generated by Sree Meenakshi Textiles are uploaded to the customer\'s "My Orders -> Documents" section upon billing and dispatch.',
                      ),

                      _sectionTitle('19. WHATSAPP & ELECTRONIC COMMUNICATIONS'),
                      _paragraph(
                        'By creating an account, placing an order, or submitting an inquiry, you consent to receive electronic communications, order tracking updates, invoice links, payment confirmations, and customer support messages via WhatsApp, Email, and SMS on your registered contact details.',
                      ),

                      _sectionTitle('20. INTELLECTUAL PROPERTY'),
                      _paragraph(
                        'All content on this Website—including brand names, trademarks, logos ("HASH ZONE", "SREE MEENAKSHI TEXTILES"), product photography, catalog styling, graphic design, user interface layout, software code, and textual descriptions—is the exclusive intellectual property of Sree Meenakshi Textiles and protected under Indian and international copyright and trademark laws. Unauthorized reproduction, scraping, or commercial duplication is strictly prohibited.',
                      ),

                      _sectionTitle('21. LIMITATION OF LIABILITY'),
                      _paragraph(
                        'To the maximum extent permitted by applicable Indian law (including the Consumer Protection Act, 2019 and the Sale of Goods Act, 1930), HASH ZONE\'s total aggregate liability arising out of or relating to any order or purchase shall not exceed the actual monetary amount paid by the customer for the specific product bundle or consignment giving rise to the claim. Nothing in these Terms attempts to exclude or limit any non-waivable statutory rights guaranteed to consumers under Indian law.',
                      ),

                      _sectionTitle('22. FORCE MAJEURE'),
                      _paragraph(
                        'HASH ZONE shall not be held liable for failure or delay in manufacturing, order processing, or logistics fulfillment caused by circumstances beyond reasonable control, including natural disasters, extreme weather, strikes, labor unrest, fabric mill supply shutdowns, transport blockades, power grid disruptions, government restrictions, epidemics, or telecommunication outages.',
                      ),

                      _sectionTitle('23. GOVERNING LAW & JURISDICTION'),
                      _paragraph(
                        'These Terms and any transactions conducted on this Website shall be governed by, construed, and enforced in accordance with the laws of the Republic of India. Subject to the dispute resolution mechanism below, the competent courts at Tiruppur, Tamil Nadu, India shall have exclusive jurisdiction over all legal proceedings arising hereunder.',
                      ),

                      _sectionTitle('24. DISPUTE RESOLUTION & GRIEVANCE REDRESSAL'),
                      _paragraph(
                        'In case of any grievance, complaint, or dispute regarding catalog listings, bundle orders, payments, or services, customers are encouraged to first contact our Grievance Officer at grievance@hashzone.co.in or via our dedicated Grievance Redressal mechanism. We commit to acknowledging grievances within 48 hours and working toward an amicable resolution in good faith within 30 days.',
                      ),

                      _sectionTitle('25. CONTACT INFORMATION'),
                      _paragraph(
                        'For questions or clarifications regarding these Terms & Conditions, please contact us:\n\n'
                        '• Enterprise: SREE MEENAKSHI TEXTILES (HASH ZONE)\n'
                        '• Operations: Tiruppur, Tamil Nadu, India\n'
                        '• Email: support@hashzone.co.in / legal@hashzone.co.in\n'
                        '• Grievance Desk: grievance@hashzone.co.in\n'
                        '• Phone / WhatsApp: +91 98848 75578 (Mon-Sat, 10:00 AM - 7:00 PM IST)',
                      ),

                      _sectionTitle('26. MODIFICATIONS TO TERMS'),
                      _paragraph(
                        'HASH ZONE reserves the right to amend, update, or revise these Terms at any time to reflect operational, commercial, or regulatory changes. Updated terms become effective immediately upon posting to this page, with the revised "Last Updated" date displayed at the top. Continued use of the Website after any modifications constitutes acceptance of the revised Terms.',
                      ),

                      const SizedBox(height: 40),
                      _buildBottomBackAction(context),
                    ],
                  ),
                ),
              ),
            ),

            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.black, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'HASH ZONE is a dedicated wholesale garment manufacturer operating directly from Tiruppur, Tamil Nadu. Please review these Terms carefully before registering an account or submitting wholesale bundle orders.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: const Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          height: 1.7,
          color: const Color(0xFF444444),
        ),
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: const Color(0xFF444444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBackAction(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.black),
          label: Text('RETURN TO PREVIOUS PAGE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.black)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
