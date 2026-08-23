import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';
import '../../utils/seo_helper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1150;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Privacy Policy | HASH ZONE Wholesale Garments',
        description: 'Learn how HASH ZONE (Sree Meenakshi Textiles, Tiruppur) collects, uses, protects, and handles your personal information, address details, and payment verification records.',
        keywords: 'HashZone Privacy Policy, Customer Data Protection, Wholesale Privacy Terms, Tiruppur Textiles Privacy',
        path: '/privacy',
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
                    'PRIVACY POLICY',
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

                      _sectionTitle('1. INTRODUCTION & SCOPE'),
                      _paragraph(
                        'This Privacy Policy describes the policies and procedures of Sree Meenakshi Textiles ("SMT", "HASH ZONE", "we", "us", or "our") regarding the collection, use, processing, storage, and disclosure of your information when you use our website (hashzone.co.in / hashzone.com) and associated mobile web services (collectively, the "Platform"). We are committed to safeguarding the privacy and personal data of our wholesale buyers, retail partners, and visitors in accordance with applicable Indian laws, including the Information Technology Act, 2000, the Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011, and the Digital Personal Data Protection Act, 2023 framework.',
                      ),

                      _sectionTitle('2. INFORMATION WE COLLECT'),
                      _paragraph(
                        'To provide seamless wholesale garment manufacturing services, order fulfillment, and legal compliance, we collect the following categories of information when you interact with our platform:',
                      ),

                      _subTitle('A. Account & Contact Information'),
                      _bulletPoint('Full Name and Business / Commercial Entity Name (if provided).'),
                      _bulletPoint('Email Address (used for authentication, order receipts, and account notices).'),
                      _bulletPoint('Mobile Phone Number and WhatsApp Contact Number (used for order dispatch coordination, UTR confirmation, and customer support).'),
                      _bulletPoint('Authentication Information (Firebase Auth credentials or Google OAuth display name, email, and profile avatar if using Google sign-in).'),

                      _subTitle('B. Primary & Delivery Address Information'),
                      _bulletPoint('Complete 7-field postal delivery address: Door / Building Number, Road / Street Name, Area / Locality, City, State, 6-Digit PIN Code, and Landmark.'),

                      _subTitle('C. Order & Commercial Transaction Information'),
                      _bulletPoint('Wholesale bundle specifications selected, sizing breakdown, piece count, unit bundle price, and total order amounts.'),
                      _bulletPoint('Order timestamps, progress statuses (Received, Confirmed, Dispatched, Cancelled), and fulfillment history.'),
                      _bulletPoint('System receipts and official GST tax invoice documents generated for commercial accounting.'),

                      _subTitle('D. Payment-Related Verification Information'),
                      _bulletPoint('12-digit Unique Transaction Reference (UTR / Bank Transaction ID) entered during Bank Transfer / UPI checkout.'),
                      _bulletPoint('Payment Proof Screenshots uploaded by the customer solely for transaction verification.'),
                      _bulletPoint('Verification timestamp, admin review notes, and verification outcome status.'),

                      _subTitle('E. Customer Support & Inquiries'),
                      _bulletPoint('Messages, inquiries, and communication logs submitted via our Contact Us form, Support Desk, or official WhatsApp Business channel.'),

                      _sectionTitle('3. PURPOSE OF DATA COLLECTION & PROCESSING'),
                      _paragraph(
                        'We collect and process personal data exclusively for lawful, legitimate operational purposes, including:',
                      ),
                      _bulletPoint('Creating, maintaining, and authenticating your customer account.'),
                      _bulletPoint('Processing, cutting, packaging, and dispatching wholesale apparel orders.'),
                      _bulletPoint('Verifying bank transfer payments and matching UTR references against bank credits.'),
                      _bulletPoint('Generating and delivering system receipts and official GST tax invoices.'),
                      _bulletPoint('Coordinating freight, surface transport, and courier logistics to your delivery address.'),
                      _bulletPoint('Providing responsive customer service, resolving inquiries, and handling return/refund requests.'),
                      _bulletPoint('Sending critical transactional updates via WhatsApp, Email, and SMS regarding order status and AWB tracking.'),
                      _bulletPoint('Preventing fraudulent transactions, abuse, security breaches, and ensuring platform integrity.'),
                      _bulletPoint('Complying with statutory accounting, tax, and legal obligations under Indian law.'),

                      _sectionTitle('4. DISCLOSURE TO THIRD-PARTY SERVICE PROVIDERS'),
                      _paragraph(
                        'We do not sell, rent, or trade your personal information to marketing brokers or third-party advertisers. We disclose data only to trusted infrastructure and operational service providers necessary to operate the Platform:',
                      ),
                      _bulletPoint('Google Firebase / Firestore: Secure cloud database, user authentication, and access rule management.'),
                      _bulletPoint('Google Identity Services: Secure OAuth sign-in enabling one-tap Google authentication.'),
                      _bulletPoint('Cloudinary: High-performance cloud content delivery network for garment catalog imagery.'),
                      _bulletPoint('Backblaze B2 Cloud Storage: Encrypted, highly reliable cloud storage for generated invoice PDFs and transaction records.'),
                      _bulletPoint('WhatsApp Business: Operational channel for real-time order inquiries, dispatch notifications, and customer support.'),
                      _bulletPoint('Logistics & Courier Partners (e.g., VRL Logistics, Professional Couriers, Delhivery, DTDC, India Post): Required recipient name, contact number, and destination address for package delivery.'),

                      _sectionTitle('5. PAYMENT PROOF & SCREENSHOT PRIVACY'),
                      _paragraph(
                        'Because HASH ZONE utilizes Direct Bank Transfer and UPI settlement to eliminate gateway surcharges, customers may upload a payment screenshot as verification proof. We treat payment proof with strict confidentiality:',
                      ),
                      _bulletPoint('Payment screenshots are stored securely in protected storage accessible solely by authorized HASH ZONE administrators.'),
                      _bulletPoint('Payment proofs are never published publicly, indexed by search engines, or shared with unrelated third parties.'),
                      _bulletPoint('Information visible in payment proofs (e.g., UTR, account name, amount) is used strictly to reconcile bank credit with order records.'),

                      _sectionTitle('6. DATA RETENTION POLICY'),
                      _paragraph(
                        'We retain personal information, address records, and order transaction history for as long as your account remains active or as reasonably necessary to fulfill wholesale orders, provide ongoing support, and comply with mandatory statutory obligations (including Indian Goods and Services Tax (GST) laws, Companies Act, and income tax regulations requiring commercial transaction record retention for up to 8 financial years). When data is no longer required, it is securely archived, anonymized, or deleted.',
                      ),

                      _sectionTitle('7. DATA SECURITY MEASURES'),
                      _paragraph(
                        'We implement industry-standard technical, administrative, and organizational security measures to protect personal data against unauthorized access, alteration, disclosure, or destruction. These include:',
                      ),
                      _bulletPoint('HTTPS / TLS 1.3 encryption across all website communications and data transfers.'),
                      _bulletPoint('Granular Firestore Security Rules restricting customer data access strictly to the authenticated account owner and authorized administrators.'),
                      _bulletPoint('Role-based administrative controls with restricted privileges.'),
                      _bulletPoint('Secure cloud storage architectures with encrypted at-rest and in-transit configurations.'),
                      _paragraph(
                        'While we maintain stringent security safeguards, no electronic transmission over the Internet or digital storage method is completely impervious; we continuously monitor and upgrade our security infrastructure.',
                      ),

                      _sectionTitle('8. YOUR DATA RIGHTS'),
                      _paragraph(
                        'Subject to applicable Indian data protection laws, customers registered with HASH ZONE have the following rights:',
                      ),
                      _bulletPoint('Right of Access & Review: You can view and review your personal profile, saved addresses, and order history anytime in "My Account".'),
                      _bulletPoint('Right to Rectification: You can update your profile information or edit saved addresses directly via "My Account -> Addresses" or "My Account -> Edit Profile".'),
                      _bulletPoint('Right to Withdraw Consent / Account Closure: You may request the deactivation of your account and cessation of non-statutory communications by writing to our Privacy Desk.'),
                      _bulletPoint('Right to Grievance Redressal: You have the right to lodge a privacy grievance with our designated Grievance Officer.'),

                      _sectionTitle('9. COOKIES & LOCAL STORAGE'),
                      _paragraph(
                        'Our platform uses browser local storage and essential session cookies strictly for functional operations (such as maintaining your active authentication session, remembering guest cart contents, and preserving interface preferences). We do not deploy third-party behavioral tracking or cross-site advertising cookies.',
                      ),

                      _sectionTitle('10. MINORS\' PRIVACY'),
                      _paragraph(
                        'Our Platform and wholesale catalog are not targeted at or designed for children under the age of 18. We do not knowingly collect personal data from minors. If we become aware that a minor has provided personal information without parental or legal guardian consent, we will take prompt steps to remove such records.',
                      ),

                      _sectionTitle('11. GRIEVANCE REDRESSAL & PRIVACY CONTACT'),
                      _paragraph(
                        'If you have any questions, concerns, complaints, or data requests regarding this Privacy Policy or our data handling practices, please contact our designated Grievance Officer:\n\n'
                        '• Grievance Officer: Legal & Compliance Officer\n'
                        '• Enterprise: SREE MEENAKSHI TEXTILES (HASH ZONE)\n'
                        '• Address: Tiruppur, Tamil Nadu, India\n'
                        '• Dedicated Privacy Email: privacy@hashzone.co.in / grievance@hashzone.co.in\n'
                        '• General Support: support@hashzone.co.in\n'
                        '• Phone / WhatsApp: +91 98848 75578 (Mon-Sat, 10:00 AM - 7:00 PM IST)',
                      ),

                      _sectionTitle('12. UPDATES TO THIS PRIVACY POLICY'),
                      _paragraph(
                        'We may update this Privacy Policy periodically to reflect changes in our legal requirements, data protection standards, or operational practices. When updates are published, the revised policy will be posted on this page with an updated "Last Updated" timestamp. We encourage users to review this page periodically.',
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
          const Icon(Icons.shield_outlined, color: Colors.black, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Your privacy and data security are central to our wholesale operations. HASH ZONE never sells customer data. All personal details, delivery addresses, and payment verification records are handled with strict commercial confidentiality.',
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
