import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';
import '../../utils/seo_helper.dart';

class GrievanceRedressalScreen extends StatelessWidget {
  const GrievanceRedressalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1150;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Grievance Redressal Mechanism | HASH ZONE Wholesale',
        description: 'Statutory grievance redressal mechanism, Grievance Officer contact details, and resolution timelines for HASH ZONE (Sree Meenakshi Textiles, Tiruppur) under Indian E-Commerce and IT rules.',
        keywords: 'HashZone Grievance Redressal, Grievance Officer Tiruppur, E-commerce Compliance India, Customer Support Escallation',
        path: '/grievance',
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
                    'GRIEVANCE REDRESSAL',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 40 : 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'STATUTORY REDRESSAL MECHANISM · CONSUMER PROTECTION (E-COMMERCE) RULES',
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

                      _sectionTitle('1. STATUTORY FRAMEWORK'),
                      _paragraph(
                        'In accordance with the Consumer Protection Act, 2019, the Consumer Protection (E-Commerce) Rules, 2020, and the Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021, Sree Meenakshi Textiles (operating HASH ZONE) has established a structured, transparent Grievance Redressal Mechanism to address customer complaints, product quality concerns, payment verification issues, and data privacy requests promptly and impartially.',
                      ),

                      _sectionTitle('2. DESIGNATED GRIEVANCE OFFICER DETAILS'),
                      _paragraph(
                        'Customers, wholesale partners, and visitors may reach out directly to our appointed Grievance Officer regarding any unresolved concern:',
                      ),
                      _buildGrievanceOfficerCard(),
                      const SizedBox(height: 16),

                      _sectionTitle('3. GRIEVANCE SUBMISSION PROCEDURE'),
                      _paragraph(
                        'To enable swift investigation and resolution, please submit your formal grievance via Email to grievance@hashzone.co.in with the following details:',
                      ),
                      _bulletPoint('Customer Name, Registered Mobile Number, and WhatsApp Number.'),
                      _bulletPoint('Order ID and Product SKU / Bundle description (if complaint relates to a specific purchase).'),
                      _bulletPoint('Bank Transfer UTR / Transaction Reference (if complaint relates to payment verification or refunds).'),
                      _bulletPoint('Comprehensive description of the grievance along with supporting photographic or video evidence.'),
                      _bulletPoint('Previous customer support ticket references or communication logs (if applicable).'),

                      _sectionTitle('4. RESOLUTION TIMELINE & ESCALATION MATRIX'),
                      _paragraph(
                        'We adhere to strict operational service-level agreements (SLAs) for grievance handling:',
                      ),
                      _subTitle('Stage 1 — Formal Acknowledgement (Within 48 Hours)'),
                      _paragraph(
                        'Upon receipt of your grievance email, our Grievance Desk will log the complaint, assign a unique Grievance Tracking ID, and acknowledge receipt within 48 business hours.',
                      ),
                      _subTitle('Stage 2 — Internal Investigation (Within 5 to 7 Business Days)'),
                      _paragraph(
                        'The Grievance Officer will liaise with our manufacturing, packaging, quality assurance, accounts, or courier logistics departments to inspect the facts and ascertain corrective action.',
                      ),
                      _subTitle('Stage 3 — Final Resolution & Closure (Within 15 to 30 Days)'),
                      _paragraph(
                        'We commit to resolving all grievances fairly and communicating the final resolution in writing within a maximum of 30 days from receipt, as mandated under applicable Indian law.',
                      ),

                      _sectionTitle('5. CATEGORIES OF GRIEVANCES HANDLED'),
                      _paragraph(
                        'Our Grievance Redressal Desk addresses concerns across all commercial and operational facets:',
                      ),
                      _bulletPoint('Wholesale Product Quality & Manufacturing Defects: Inquiries, stitching defects, fabric quality discrepancies, or wrong bundle shipments.'),
                      _bulletPoint('Payment Reconciliation & UTR Verification: Inquiries regarding bank transfer verification delays, duplicate credits, or unverified deposits.'),
                      _bulletPoint('Refunds & Commercial Settlements: Status of approved cancellations, credit notes, or refund processing within our 7-working-day timeframe.'),
                      _bulletPoint('Courier Delivery & Logistics Issues: Severe transit delays, damaged parcels, lost packages, or AWB tracking errors.'),
                      _bulletPoint('Data Protection & Privacy Requests: Requests for review, update, rectification, or withdrawal of consent under our Privacy Policy.'),

                      _sectionTitle('6. AMICABLE DISPUTE RESOLUTION'),
                      _paragraph(
                        'HASH ZONE believes in maintaining long-term, mutually beneficial commercial relationships with all wholesale buyers and retail businesses. In the event of any dispute arising out of or relating to your use of the Platform, both parties agree to engage in good-faith negotiations to achieve an amicable commercial settlement before initiating formal legal proceedings.',
                      ),

                      _sectionTitle('7. JURISDICTION'),
                      _paragraph(
                        'All legal disputes that cannot be settled amicably through the Grievance Redressal Mechanism shall be subject to the exclusive jurisdiction of the competent courts located at Tiruppur, Tamil Nadu, India.',
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
          const Icon(Icons.gavel_outlined, color: Colors.black, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'HASH ZONE is committed to fair wholesale commercial practices and consumer protection. All grievances submitted through our official Grievance Desk are acknowledged within 48 hours and resolved within 30 days.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: const Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrievanceOfficerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_pin_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GRIEVANCE & COMPLIANCE DESK',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sree Meenakshi Textiles · HASH ZONE',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 16),
          _officerRow(Icons.badge_outlined, 'Designation', 'Nodal Grievance & Compliance Officer'),
          _officerRow(Icons.email_outlined, 'Grievance Email', 'grievance@hashzone.co.in'),
          _officerRow(Icons.phone_outlined, 'Helpline / WhatsApp', '+91 98848 75578'),
          _officerRow(Icons.location_on_outlined, 'Registered Facility', 'Sree Meenakshi Textiles, Tiruppur, Tamil Nadu, India - 641602'),
          _officerRow(Icons.access_time_outlined, 'Working Hours', 'Monday to Saturday, 10:00 AM – 7:00 PM IST (Excl. Public Holidays)'),
        ],
      ),
    );
  }

  Widget _officerRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF555555)),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF444444)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF222222), height: 1.4),
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
