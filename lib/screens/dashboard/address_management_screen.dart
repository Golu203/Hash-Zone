import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../services/address_service.dart';
import '../../widgets/navbar.dart';
import '../../widgets/smart_back_button.dart';
import '../../widgets/unified_address_form.dart';

class AddressManagementScreen extends StatelessWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<CustomerAuthProvider>();
    final addr = context.watch<AddressProvider>();
    final isMobile = MediaQuery.of(context).size.width < 700;
    final uid = auth.firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 64, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const HZSmartBackButton(fallbackRoute: '/dashboard', label: null),
                    const SizedBox(width: 8),
                    Text('My Addresses', style: GoogleFonts.cormorantGaramond(fontSize: 26, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('Add New', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _showAddressDialog(context, uid, null),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (addr.isLoading)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                else if (addr.addresses.isEmpty)
                  _emptyState(context, uid)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addr.addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final a = addr.addresses[i];
                      return _AddressCard(
                        address: a,
                        uid: uid,
                        onEdit: () => _showAddressDialog(context, uid, a),
                        onDelete: () => _confirmDelete(context, uid, a.id, addr),
                        onSetDefault: () => addr.setDefault(uid, a.id),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, size: 56, color: Colors.black26),
          const SizedBox(height: 16),
          Text('No addresses saved', style: GoogleFonts.inter(fontSize: 15, color: Colors.black45)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => _showAddressDialog(context, uid, null),
            child: Text('Add Your First Address', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String id, AddressProvider addr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Address', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22)),
        content: Text('Are you sure you want to delete this address?', style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, elevation: 0),
            onPressed: () async { Navigator.pop(ctx); await addr.deleteAddress(uid, id); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context, String uid, CustomerAddress2? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddressDialog(uid: uid, existing: existing),
    );
  }
}

// ── Address Card ──────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final CustomerAddress2 address;
  final String uid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.uid,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: address.isDefault ? Colors.black : const Color(0xFFDDDDDD),
          width: address.isDefault ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                  child: Text('DEFAULT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                )
              else
                TextButton(
                  onPressed: onSetDefault,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  child: Text('Set as Default', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, decoration: TextDecoration.underline)),
                ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54), onPressed: onEdit, padding: EdgeInsets.zero),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFD32F2F)), onPressed: onDelete, padding: EdgeInsets.zero),
            ],
          ),
          const SizedBox(height: 10),
          if (address.label.isNotEmpty) ...[
            Text(address.label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
          ],
          Text(
            [address.doorNumber, address.road, address.area, address.city]
                .where((s) => s.isNotEmpty)
                .join(', '),
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.5),
          ),
          if (address.landmark.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Near: ${address.landmark}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
          ],
        ],
      ),
    );
  }
}

// ── Address Form Dialog ───────────────────────────────────────────────────────
class _AddressDialog extends StatefulWidget {
  final String uid;
  final CustomerAddress2? existing;

  const _AddressDialog({required this.uid, this.existing});

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  bool _isSaving = false;

  Future<void> _handleSave(CustomerAddress2 addr) async {
    setState(() => _isSaving = true);
    try {
      final svc = AddressService();
      if (widget.existing == null) {
        await svc.addAddress(widget.uid, addr);
      } else {
        await svc.updateAddress(widget.uid, addr);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address.', style: GoogleFonts.inter()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final profile = context.read<CustomerAuthProvider>().profile;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 80, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.existing == null ? 'Add Address' : 'Edit Address',
                  style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            UnifiedAddressForm(
              initialAddress: widget.existing,
              defaultFullName: profile?.displayName,
              defaultPhone: profile?.phoneNumber,
              defaultCompany: profile?.companyName,
              submitButtonText: widget.existing == null ? 'Save Address' : 'Update Address',
              isSaving: _isSaving,
              onSave: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
