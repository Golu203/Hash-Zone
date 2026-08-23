import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';
import '../../utils/seo_helper.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1150;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Refund & Cancellation Policy | HASH ZONE Wholesale',
        description: 'Understand HASH ZONE\'s wholesale order cancellation procedures, return criteria for manufacturing defects, and our 7-working-day refund processing policy.',
        keywords: 'HashZone Refund Policy, Wholesale Cancellation Policy, Garment Return Policy Tiruppur, 7 Day Refund Policy',
        path: '/refund-policy',
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
                    'REFUND & CANCELLATION POLICY',
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

                      _sectionTitle('1. OVERVIEW'),
                      _paragraph(
                        'At HASH ZONE (Sree Meenakshi Textiles, Tiruppur), we manufacture and supply wholesale clothing bundles directly to commercial buyers and retail partners across India. Because our products are manufactured and batched in complete wholesale bundles and sold at factory-direct pricing, our cancellation, return, and refund policies are structured specifically to balance rapid order dispatch with commercial fairness.',
                      ),

                      _sectionTitle('2. ORDER CANCELLATION BY CUSTOMER'),
                      _subTitle('A. Cancellation Prior to Administrative Confirmation'),
                      _paragraph(
                        'If you have placed an order but have not yet submitted payment verification or if payment verification is pending, you may cancel your order free of charge by notifying HASH ZONE Support via WhatsApp (+91 98848 75578) or Email (support@hashzone.co.in).',
                      ),

                      _subTitle('B. Cancellation After Confirmation but Prior to Dispatch'),
                      _paragraph(
                        'If your payment has been verified and confirmed but your consignment has not yet been packed and handed over to our courier/transport carrier, cancellation may be requested. If approved, a full refund of the product bundle price will be initiated.',
                      ),

                      _subTitle('C. Cancellation After Package Dispatch'),
                      _paragraph(
                        'Once a consignment has been dispatched from our Tiruppur factory and an Air Waybill (AWB) or lorry receipt has been issued by our logistics partner, the order CANNOT be cancelled. The shipment will proceed to the destination address for standard delivery.',
                      ),

                      _sectionTitle('3. ORDER REJECTION & CANCELLATION BY HASHZONE'),
                      _paragraph(
                        'HASH ZONE reserves the right to cancel an order in the following circumstances:',
                      ),
                      _bulletPoint('Unavailability of selected fabric, yarn stock, or manufacturing capacity.'),
                      _bulletPoint('Inability to verify bank transfer credit or mismatched UTR reference.'),
                      _bulletPoint('Destination PIN code identified as completely non-serviceable by all courier/transport agencies.'),
                      _bulletPoint('Technical pricing or catalog listing error.'),
                      _paragraph(
                        'In all instances where HASH ZONE cancels an order after receiving full payment, a 100% refund of the verified amount received will be issued without any administrative deductions.',
                      ),

                      _sectionTitle('4. DUPLICATE & ERRONEOUS PAYMENTS'),
                      _paragraph(
                        'If you inadvertently transfer an excess amount or execute duplicate bank transfers for the same order, please notify support immediately with both UTR reference numbers and payment proofs. Upon bank reconciliation, the excess or duplicate amount will be refunded in full.',
                      ),

                      _sectionTitle('5. REFUND TIMELINE & METHOD'),
                      _paragraph(
                        'Eligible refunds will generally be processed within 7 working days after approval/confirmation of the refund by HASH ZONE management.',
                      ),
                      _paragraph(
                        'Key points regarding refund processing:',
                      ),
                      _bulletPoint('Refund Method: Refunds are issued via direct NEFT / IMPS / RTGS bank transfer to the verified source bank account or UPI ID from which the payment originated.'),
                      _bulletPoint('Bank Processing Times: While HASH ZONE initiates and approves refunds within 7 working days, the exact time required for the credited funds to reflect in your account depends on your banking institution\'s inter-bank clearing cycles.'),
                      _bulletPoint('Refund Notification: You will receive an official refund transaction reference and confirmation via WhatsApp and Email upon completion.'),

                      _sectionTitle('6. DAMAGED, DEFECTIVE OR WRONG PRODUCTS'),
                      _paragraph(
                        'We maintain stringent multi-point quality inspections during garment stitching, finishing, and bundling in Tiruppur. However, if you receive a parcel with severe transit damage, manufacturing defects, or wrong bundle items, please follow this procedure:',
                      ),
                      _bulletPoint('Timeline: Report the issue to HASH ZONE Support within 48 HOURS of parcel delivery.'),
                      _bulletPoint('Evidence: Provide clear photographs and an unboxing video showing the outer parcel label, barcode, intact packaging, and the specific defective or mismatched garments.'),
                      _bulletPoint('Assessment: Our quality assurance team will inspect the evidence within 24 business hours.'),
                      _bulletPoint('Resolution: If a manufacturing defect or wrong shipment is verified, HASH ZONE will arrange for free replacement pieces/bundle, a credit note, or a proportionate refund of the affected items.'),

                      _sectionTitle('7. NON-RETURNABLE SITUATIONS'),
                      _paragraph(
                        'The following situations are not eligible for returns or refunds:',
                      ),
                      _bulletPoint('Minor dye lot, fabric texture, or color shade variations resulting from digital screen display settings.'),
                      _bulletPoint('Garments that have been washed, worn, ironed, dry-cleaned, re-tagged, or altered in any manner.'),
                      _bulletPoint('Parcels where damages or discrepancies were not reported within the mandatory 48-hour window from delivery.'),
                      _bulletPoint('Customer change of mind or unsold inventory at the buyer\'s retail store.'),
                      _bulletPoint('Consignments returned due to incorrect delivery address provided by the customer or customer refusal to accept the delivery (RTO charges apply).'),

                      _sectionTitle('8. FAILED DELIVERY & RETURN TO ORIGIN (RTO)'),
                      _paragraph(
                        'If a parcel is returned to our Tiruppur facility because the courier was unable to deliver after multiple attempts, incorrect contact details, or customer refusal, the actual two-way shipping freight incurred will be deducted from any eligible refund. Alternatively, the customer may pay re-dispatch freight for re-shipping the parcel.',
                      ),

                      _sectionTitle('9. SUPPORT & REFUND ASSISTANCE'),
                      _paragraph(
                        'To initiate a cancellation, report a damaged item, or track an approved refund, please contact our support desk:\n\n'
                        '• Email: support@hashzone.co.in / refunds@hashzone.co.in\n'
                        '• Grievance Officer: grievance@hashzone.co.in\n'
                        '• Phone / WhatsApp Support: +91 98848 75578 (Mon-Sat, 10:00 AM - 7:00 PM IST)\n'
                        '• Facility: SREE MEENAKSHI TEXTILES, Tiruppur, Tamil Nadu, India',
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
          const Icon(Icons.currency_rupee_outlined, color: Colors.black, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Eligible refunds approved by HASH ZONE management will generally be processed within 7 working days after approval/confirmation. We ensure transparent, fair commercial resolutions for all verified wholesale buyers.',
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

  Widget _subTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF111111),
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
