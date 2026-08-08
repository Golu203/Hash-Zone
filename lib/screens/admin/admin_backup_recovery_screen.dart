import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';

class AdminBackupRecoveryScreen extends StatefulWidget {
  const AdminBackupRecoveryScreen({super.key});

  @override
  State<AdminBackupRecoveryScreen> createState() => _AdminBackupRecoveryScreenState();
}

class _AdminBackupRecoveryScreenState extends State<AdminBackupRecoveryScreen> {
  final _service = BackupService();

  bool _isBackingUp = false;
  String _backupStage = '';
  double _backupProgress = 0.0;

  bool _isRestoring = false;
  String _restoreStage = '';
  double _restoreProgress = 0.0;
  RestoreReport? _lastRestoreReport;

  Future<void> _handleCreateBackup() async {
    setState(() {
      _isBackingUp = true;
      _backupStage = 'Initializing Backup...';
      _backupProgress = 0.0;
    });

    try {
      final adminEmail = AuthService().currentUser?.email ?? 'Admin User';
      final package = await _service.createBackup(
        adminUser: adminEmail,
        onProgress: (stage, progress) {
          if (mounted) {
            setState(() {
              _backupStage = stage;
              _backupProgress = progress;
            });
          }
        },
      );

      final hzbString = package.toHzbString();
      final bytes = utf8.encode(hzbString);
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final filename = 'hashzone_backup_$dateStr.hzb';

      // Download file in browser
      final dataUrl = 'data:application/octet-stream;base64,${base64Encode(bytes)}';
      final uri = Uri.parse(dataUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }

      setState(() => _isBackingUp = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup package $filename created & download started!', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleUploadAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hzb'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    try {
      final hzbString = utf8.decode(file.bytes!);
      final package = BackupPackage.fromHzbString(hzbString);
      final analysis = await _service.analyzeBackup(package);

      if (mounted) {
        _showRestoreAnalysisDialog(package, analysis);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid .hzb backup file: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRestoreAnalysisDialog(BackupPackage package, RestoreAnalysis analysis) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Analyze Backup', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Backup Version', analysis.manifest.backupVersion),
              _infoRow('Created Date', analysis.manifest.createdAt.toLocal().toString().split('.').first),
              _infoRow('Created By', analysis.manifest.createdBy),
              const Divider(height: 20),
              _infoRow('Total Collections', analysis.collectionBreakdown.length.toString()),
              _infoRow('Total Records', analysis.totalRecords.toString()),
              _infoRow('Will Create', analysis.willCreate.toString()),
              _infoRow('Will Update', analysis.willUpdate.toString()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Smart Restore compares records by permanent IDs to prevent duplicates. A Safety Backup will be created automatically before restoring.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF57C00)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              _performRestore(package);
            },
            child: const Text('RESTORE BACKUP'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(BackupPackage package) async {
    setState(() {
      _isRestoring = true;
      _restoreStage = 'Creating Safety Backup...';
      _restoreProgress = 0.0;
    });

    final adminEmail = AuthService().currentUser?.email ?? 'Admin User';
    final report = await _service.restoreBackup(
      package: package,
      adminUser: adminEmail,
      onProgress: (stage, progress) {
        if (mounted) {
          setState(() {
            _restoreStage = stage;
            _restoreProgress = progress;
          });
        }
      },
    );

    setState(() {
      _isRestoring = false;
      _lastRestoreReport = report;
    });

    if (mounted) {
      _showRestoreReportDialog(report);
    }
  }

  void _showRestoreReportDialog(RestoreReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore Report', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Products Created', report.productsCreated.toString()),
            _infoRow('Products Updated', report.productsUpdated.toString()),
            _infoRow('Customers Updated', report.customersUpdated.toString()),
            _infoRow('Orders Updated', report.ordersUpdated.toString()),
            _infoRow('Collections Restored', report.collectionsUpdated.toString()),
            if (report.errors.isNotEmpty)
              Text('Errors: ${report.errors.length}', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: Text(
          'BACKUP & RECOVERY',
          style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2.5, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. CREATE FULL BACKUP CARD ──────────────────────────────
                _buildCard(
                  title: 'FULL DATABASE BACKUP',
                  subtitle: 'Generate a single compressed .hzb file containing all products, orders, settings, and URLs.',
                  icon: Icons.cloud_download_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isBackingUp) ...[
                        LinearProgressIndicator(value: _backupProgress, backgroundColor: const Color(0xFFEEEEEE), valueColor: const AlwaysStoppedAnimation(Colors.black)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(_backupStage, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('${(_backupProgress * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isBackingUp ? null : _handleCreateBackup,
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(_isBackingUp ? 'GENERATING BACKUP...' : 'CREATE FULL BACKUP (.HZB)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 2. RESTORE BACKUP CARD ──────────────────────────────────
                _buildCard(
                  title: 'SMART BACKUP RESTORE',
                  subtitle: 'Upload a .hzb backup file. Compares permanent IDs to update existing and create missing records without duplicates.',
                  icon: Icons.cloud_upload_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isRestoring) ...[
                        LinearProgressIndicator(value: _restoreProgress, backgroundColor: const Color(0xFFEEEEEE), valueColor: const AlwaysStoppedAnimation(Color(0xFFD32F2F))),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(_restoreStage, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                            const Spacer(),
                            Text('${(_restoreProgress * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isRestoring ? null : _handleUploadAndRestore,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(_isRestoring ? 'RESTORING BACKUP...' : 'RESTORE BACKUP (.HZB)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                if (_lastRestoreReport != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFA5D6A7))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last Restore Summary', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                        const SizedBox(height: 8),
                        Text('Products Created: ${_lastRestoreReport!.productsCreated} | Products Updated: ${_lastRestoreReport!.productsUpdated}'),
                        Text('Orders Updated: ${_lastRestoreReport!.ordersUpdated} | Collections Restored: ${_lastRestoreReport!.collectionsUpdated}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String subtitle, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Colors.black),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, height: 1.4)),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
