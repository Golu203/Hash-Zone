import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/business_provider.dart';
import '../widgets/footer.dart';
import '../widgets/navbar.dart';

import '../utils/seo_helper.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _sendFormWhatsApp(String targetNumber) {
    if (_formKey.currentState!.validate()) {
      final text = '''
Hello HASH ZONE,

Customer Inquiry:
Name: ${_nameController.text.trim()}
Phone: ${_phoneController.text.trim()}

Message:
${_messageController.text.trim()}
''';
      final encoded = Uri.encodeComponent(text);
      final rawNum = targetNumber.replaceAll(RegExp(r'[^\d+]'), '');
      _launchUrl('https://wa.me/$rawNum?text=$encoded');
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = Provider.of<BusinessProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Contact Bulk Clothing Exporters in Tiruppur | HASH ZONE',
        description: 'Get in touch with HASH ZONE\'s wholesale sales team in Tiruppur, Tamil Nadu, India. Inquire for bulk pricing, Custom OEM/ODM garment factory services.',
        keywords: 'Contact HASH ZONE, Tiruppur Clothing Factory Address, Bulk Clothing Supplier contact, Garment Exporter Tiruppur, Tiruppur, Tamil Nadu, India',
        path: '/contact',
      );
    });

    return Scaffold(
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Page Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 60 : 36,
                horizontal: isDesktop ? 32 : 20,
              ),
              color: const Color(0xFF111111),
              child: Column(
                children: [
                  Text(
                    'CONTACT',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 42 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GET IN TOUCH WITH US',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      letterSpacing: 2.0,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildStoreInfoCard(context, business)),
                          const SizedBox(width: 40),
                          Expanded(child: _buildInquiryForm(context, business)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildStoreInfoCard(context, business),
                          const SizedBox(height: 32),
                          _buildInquiryForm(context, business),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 80),
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoCard(BuildContext context, BusinessProvider business) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.location_on_outlined, 'Address', business.settings.storeAddress),
          const SizedBox(height: 16),
          _buildClickableContactsRow(Icons.phone_outlined, 'Contact', business.settings.contactNumbers),
          const SizedBox(height: 16),
          _buildClickableWhatsAppRow(Icons.chat_outlined, 'WhatsApp', business.settings.whatsAppNumber),
          const SizedBox(height: 16),
          _infoRow(Icons.email_outlined, 'Email Inquiry', business.settings.email),
          const SizedBox(height: 16),
          _infoRow(Icons.access_time_outlined, 'Working Hours', business.settings.businessHours),
          const SizedBox(height: 28),
          if (business.settings.googleMapsUrl.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _launchUrl(business.settings.googleMapsUrl),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('OPEN GOOGLE MAPS LOCATION'),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF333333), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666))),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111111))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickableContactsRow(IconData icon, String label, List<String> numbers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF333333), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666))),
              const SizedBox(height: 2),
              ...numbers.map((num) => InkWell(
                    onTap: () {
                      final cleanNumber = num.replaceAll(RegExp(r'[^\d+]'), '');
                      _launchUrl('tel:$cleanNumber');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        num,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickableWhatsAppRow(IconData icon, String label, String number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF333333), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666))),
              const SizedBox(height: 2),
              InkWell(
                onTap: () {
                  final rawNum = number.replaceAll(RegExp(r'[^\d+]'), '');
                  _launchUrl('https://wa.me/$rawNum');
                },
                child: Text(
                  number,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInquiryForm(BuildContext context, BusinessProvider business) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEND DIRECT INQUIRY',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.inter(color: Colors.black),
              decoration: const InputDecoration(labelText: 'Your Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              style: GoogleFonts.inter(color: Colors.black),
              decoration: const InputDecoration(labelText: 'Phone Number / WhatsApp'),
              validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              style: GoogleFonts.inter(color: Colors.black),
              decoration: const InputDecoration(labelText: 'Message or Product Order Request'),
              validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sendFormWhatsApp(business.settings.whatsAppNumber),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('SUBMIT VIA WHATSAPP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
