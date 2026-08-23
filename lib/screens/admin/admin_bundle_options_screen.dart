import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bundle_option.dart';
import '../../services/bundle_option_service.dart';

class AdminBundleOptionsScreen extends StatefulWidget {
  const AdminBundleOptionsScreen({super.key});

  @override
  State<AdminBundleOptionsScreen> createState() => _AdminBundleOptionsScreenState();
}

class _AdminBundleOptionsScreenState extends State<AdminBundleOptionsScreen> {
  final BundleOptionService _svc = BundleOptionService();
  List<BundleOption> _options = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _svc.fetchAll();
      if (mounted) setState(() { _options = all; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddEditDialog({BundleOption? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final sizesCtrl = TextEditingController(text: existing?.sizes.join(', ') ?? '');
    final piecesPerSizeCtrl = TextEditingController(
      text: existing != null && existing.piecesPerSize > 0
          ? existing.piecesPerSize.toString()
          : '',
    );
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlgState) {
          final sizesRaw = sizesCtrl.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          final pps = int.tryParse(piecesPerSizeCtrl.text.trim()) ?? 0;
          final totalPieces = sizesRaw.length * pps;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              existing == null ? 'Add Bundle Option' : 'Edit Bundle Option',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: GoogleFonts.inter(color: Colors.black),
                      decoration: const InputDecoration(labelText: 'Bundle Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: sizesCtrl,
                      style: GoogleFonts.inter(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Sizes (comma-separated)',
                        hintText: 'e.g. S, M, L, XL',
                      ),
                      onChanged: (_) => setDlgState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final parts = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                        if (parts.isEmpty) return 'Enter at least one size';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: piecesPerSizeCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: Colors.black),
                      decoration: const InputDecoration(labelText: 'Pieces Per Size'),
                      onChanged: (_) => setDlgState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PREVIEW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            sizesRaw.isEmpty ? '—' : sizesRaw.join(' · '),
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          Text(
                            'Total: ${totalPieces > 0 ? totalPieces : "—"} pieces  |  $pps pcs/size',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDlgState(() => saving = true);

                        final sizes = sizesCtrl.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        final piecesPerSize = int.parse(piecesPerSizeCtrl.text.trim());
                        final total = sizes.length * piecesPerSize;

                        try {
                          if (existing == null) {
                            await _svc.add(BundleOption(
                              id: '',
                              name: nameCtrl.text.trim(),
                              sizes: sizes,
                              totalPieces: total,
                              piecesPerSize: piecesPerSize,
                            ));
                          } else {
                            await _svc.update(existing.copyWith(
                              name: nameCtrl.text.trim(),
                              sizes: sizes,
                              totalPieces: total,
                              piecesPerSize: piecesPerSize,
                            ));
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _load();
                        } catch (e) {
                          setDlgState(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: Text(
                  saving ? 'Saving...' : (existing == null ? 'Add' : 'Save'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _toggleActive(BundleOption opt) async {
    try {
      await _svc.update(opt.copyWith(active: !opt.active));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _delete(BundleOption opt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Bundle Option?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          '"${opt.name}" will be permanently deleted. Products already using this bundle retain their saved data, but new products won\'t see this option.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _svc.delete(opt.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'BUNDLE OPTIONS',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add Bundle', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _options.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.black54, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bundle Options are reusable templates. Create them here, then assign one to each product in Edit Product → Bundle Configuration. Toggle Active/Inactive to show or hide from the product editor.',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF555555)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildOptionCard(_options[index]),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOptionCard(BundleOption opt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: opt.active ? Colors.white : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: opt.active ? const Color(0xFF000000) : const Color(0xFFBBBBBB),
          width: opt.active ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        opt.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: opt.active ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: opt.active ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: opt.active ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                        ),
                      ),
                      child: Text(
                        opt.active ? 'ACTIVE' : 'INACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: opt.active ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      opt.active ? Icons.toggle_on : Icons.toggle_off,
                      color: opt.active ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                    tooltip: opt.active ? 'Deactivate' : 'Activate',
                    onPressed: () => _toggleActive(opt),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
                    tooltip: 'Edit',
                    onPressed: () => _showAddEditDialog(existing: opt),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _delete(opt),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: opt.sizes.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statBadge('${opt.piecesPerSize} pcs/size', Icons.straighten_outlined),
              const SizedBox(width: 16),
              _statBadge('${opt.totalPieces} total pcs/bundle', Icons.inventory_2_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF666666)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF555555), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFBBBBBB)),
            const SizedBox(height: 16),
            Text('No Bundle Options Yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Text(
              'Create bundle options here, then assign them to products\nin Edit Product → Bundle Configuration.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666), height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: Text('Add First Bundle Option', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
