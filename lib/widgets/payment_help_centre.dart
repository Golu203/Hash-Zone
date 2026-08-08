import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentHelpCentre extends StatelessWidget {
  const PaymentHelpCentre({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black54,
          title: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Colors.black, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Where can I find my UTR / Reference Number?',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.all(20),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMockUiIllustration(),
                        const SizedBox(height: 20),
                        _buildWrittenGuide(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildMockUiIllustration(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _buildWrittenGuide(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrittenGuide() {
    final steps = [
      '1. Log in to your banking application or net banking portal.',
      '2. Navigate to transaction history, statements, or transfer advice.',
      '3. Locate the completed transfer made to the HashZone account.',
      '4. Find the 12-digit UTR (Unique Transaction Reference) or Ref Number.',
      '5. Copy or enter this transaction reference into the UTR field above.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Locating UTR / Bank Reference',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              s,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockUiIllustration() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.blueGrey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Bank Transfer Receipt',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SUCCESS ✓',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFEEEEEE)),
              Text('Beneficiary Name', style: GoogleFonts.inter(fontSize: 10, color: Colors.black38)),
              Text('HASH ZONE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Transfer Amount', style: GoogleFonts.inter(fontSize: 10, color: Colors.black38)),
              Text('₹49,999.00', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD32F2F), width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UTR / TRANSACTION REF NO.',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD32F2F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '239401284756',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.center_focus_strong, color: Color(0xFFD32F2F), size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sample net banking transaction receipt guidance illustration.',
          style: GoogleFonts.inter(fontSize: 10, color: Colors.black38, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
