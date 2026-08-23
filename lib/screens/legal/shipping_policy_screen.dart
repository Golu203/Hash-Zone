import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';
import '../../utils/seo_helper.dart';

class ShippingPolicyScreen extends StatelessWidget {
  const ShippingPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1150;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Shipping & Delivery Policy | HASH ZONE Wholesale',
        description: 'Detailed information regarding wholesale garment freight charges, dispatch timelines from Tiruppur, courier tracking, and delivery guidelines across India.',
        keywords: 'HashZone Shipping Policy, Wholesale Clothing Delivery India, Tiruppur Garment Dispatch, Freight Charges Policy',
        path: '/shipping-policy',
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
                    'SHIPPING & DELIVERY POLICY',
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

                      _sectionTitle('1. DISPATCH ORIGIN & MANUFACTURING HUB'),
                      _paragraph(
                        'All orders placed on HASH ZONE are processed, packaged, and dispatched directly from our garment manufacturing facility operated by Sree Meenakshi Textiles (SMT) in Tiruppur, Tamil Nadu—the renowned textile and knitwear capital of India.',
                      ),

                      _sectionTitle('2. SERVICEABLE DELIVERY LOCATIONS'),
                      _paragraph(
                        'We dispatch wholesale clothing consignments across all major states, union territories, metro cities, tier-2, tier-3 towns, and regional retail clusters throughout India. Our network connects with regional transport hubs in Tamil Nadu, Karnataka, Maharashtra, Delhi NCR, Gujarat, Kerala, Telangana, Andhra Pradesh, West Bengal, Rajasthan, Uttar Pradesh, Punjab, and other states.',
                      ),

                      _sectionTitle('3. HOW SHIPPING CHARGES ARE DETERMINED'),
                      _paragraph(
                        'Because wholesale garments consist of bulk fabric parcels (ranging from compact single-bundle parcels of 5–15 kg up to multi-carton wholesale consignments exceeding 100 kg), shipping charges are calculated separately to ensure buyers obtain the most competitive, transparent freight rates based on:',
                      ),
                      _bulletPoint('Delivery Destination (State, District, Metro vs. Remote / ODA PIN Codes).'),
                      _bulletPoint('Total Consignment Weight (Dead weight in kilograms).'),
                      _bulletPoint('Volumetric Parcel Dimensions (Length × Width × Height / Dimensional factor).'),
                      _bulletPoint('Carrier Selection (Express Air Cargo, Surface Courier, or Regional Road Transport).'),
                      _paragraph(
                        'Estimated shipping rates or logistics coordination are shared directly with the customer prior to or upon parcel handover.',
                      ),

                      _sectionTitle('4. ORDER PROCESSING & DISPATCH TIMELINE'),
                      _paragraph(
                        '• Processing Timeline: Once payment verification is confirmed by our administrative team, standard wholesale bundle orders are inspected, poly-packed, master-cartoned, and prepared for dispatch within 1 to 3 business days (excluding Sundays and national/textile holidays).\n'
                        '• Custom Bulk / Large Consignments: Custom production runs, bespoke printing, or large volume consignments (>500 pieces) may require dedicated production schedules agreed upon during inquiry.',
                      ),

                      _sectionTitle('5. ESTIMATED TRANSIT & DELIVERY TIMELINES'),
                      _paragraph(
                        'Once dispatched from Tiruppur, estimated transit times under normal logistics conditions are as follows:',
                      ),
                      _bulletPoint('South India (Tamil Nadu, Karnataka, Kerala, Andhra Pradesh, Telangana): 2 to 4 Business Days.'),
                      _bulletPoint('West & Central India (Maharashtra, Gujarat, Madhya Pradesh, Goa): 3 to 5 Business Days.'),
                      _bulletPoint('North India (Delhi NCR, Haryana, Punjab, Rajasthan, Uttar Pradesh): 4 to 6 Business Days.'),
                      _bulletPoint('East & North-East India (West Bengal, Odisha, Bihar, Assam, North-East): 5 to 8 Business Days.'),
                      _bulletPoint('Remote / Out of Delivery Area (ODA) PIN Codes: Additional 1 to 3 business days.'),
                      _paragraph(
                        'Please note that transit timelines are realistic operational estimates and do not constitute absolute guarantees, as carrier operations are subject to regional transit variables.',
                      ),

                      _sectionTitle('6. COURIER & LOGISTICS PARTNERS'),
                      _paragraph(
                        'We partner with leading surface transport operators and express courier carriers across India, including:',
                      ),
                      _bulletPoint('Surface Logistics & Cargo: VRL Logistics, TCI Express, Safechem, Professional Couriers, Navata, KPN Transport, and customer-designated Tiruppur transport booking offices.'),
                      _bulletPoint('Express Parcel Couriers: Delhivery, DTDC, Blue Dart, Trackon, and India Post Speed Post.'),

                      _sectionTitle('7. SHIPMENT TRACKING & AWB DETAILS'),
                      _paragraph(
                        'As soon as your consignment is handed over to the courier partner:',
                      ),
                      _bulletPoint('The order status in "My Account -> My Orders" updates to "Dispatched".'),
                      _bulletPoint('The official Air Waybill (AWB) number, courier company name, and direct tracking URL are populated on your order card.'),
                      _bulletPoint('An automated dispatch alert containing tracking details is transmitted to your registered WhatsApp number and Email.'),

                      _sectionTitle('8. INCORRECT ADDRESS & CUSTOMER RESPONSIBILITIES'),
                      _paragraph(
                        'The customer is solely responsible for providing an accurate and reachable delivery address during checkout. Key responsibilities include:',
                      ),
                      _bulletPoint('Ensuring Door / Flat / Building Number, Street / Road, Area, Landmark, and 6-digit PIN Code are accurate.'),
                      _bulletPoint('Providing a working mobile phone number where courier delivery personnel can coordinate delivery.'),
                      _bulletPoint('Arranging authorized personnel to receive the parcel during business hours.'),

                      _sectionTitle('9. FAILED DELIVERY ATTEMPTS & RETURN TO ORIGIN (RTO)'),
                      _paragraph(
                        'Couriers typically make up to 3 delivery attempts before classifying a parcel as undeliverable. If a shipment is returned to our Tiruppur facility (Return to Origin - RTO) due to incorrect address, unreachable contact number, commercial premises closure, or unjustified delivery refusal, the customer shall be responsible for the actual two-way freight charges incurred.',
                      ),

                      _sectionTitle('10. NON-SERVICEABLE PIN CODES'),
                      _paragraph(
                        'In the rare circumstance that a customer\'s PIN code cannot be reached by any courier or surface transport network, our customer support desk will contact you to arrange delivery to the nearest accessible transport godown / hub or facilitate an immediate 100% refund of your order.',
                      ),

                      _sectionTitle('11. TRANSIT DELAYS & FORCE MAJEURE'),
                      _paragraph(
                        'HASH ZONE is not liable for logistics transit delays caused by circumstances beyond reasonable control, including severe weather disruptions, monsoon flooding, transport union strikes, highway blockades, regional lockdown restrictions, local festive congestion, or carrier operational bottlenecks. In all such cases, our support team will actively coordinate with carrier management to expedite parcel movement.',
                      ),

                      _sectionTitle('12. RECEIVING SHIPMENTS & UNBOXING GUIDELINES'),
                      _paragraph(
                        'Upon receiving your parcel:\n'
                        '1. Check outer carton integrity and tamper-proof tape before signing the delivery manifest.\n'
                        '2. If the outer carton is severely torn or opened, record a note with the delivery agent before signing.\n'
                        '3. We strongly recommend recording a continuous video of package unboxing to protect your commercial claim in the unlikely event of item damage or missing bundles.',
                      ),

                      _sectionTitle('13. SHIPPING SUPPORT DESK'),
                      _paragraph(
                        'For questions regarding ongoing shipments, freight inquiries, or transport booking preferences, please contact us:\n\n'
                        '• Logistics & Dispatch Desk: SREE MEENAKSHI TEXTILES (HASH ZONE)\n'
                        '• Manufacturing & Hub: Tiruppur, Tamil Nadu, India\n'
                        '• Email: support@hashzone.co.in / logistics@hashzone.co.in\n'
                        '• Phone / WhatsApp: +91 98848 75578 (Mon-Sat, 10:00 AM - 7:00 PM IST)',
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
          const Icon(Icons.local_shipping_outlined, color: Colors.black, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'All wholesale orders are dispatched direct from our Tiruppur manufacturing hub with verified AWB tracking. Freight is calculated separately to provide the most economical transport rates for wholesale garment buyers.',
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
