// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';

class AdminBackupRecoveryScreen extends StatefulWidget {
  const AdminBackupRecoveryScreen({super.key});

  @override
  State<AdminBackupRecoveryScreen> createState() => _AdminBackupRecoveryScreenState();
}

class _AdminBackupRecoveryScreenState extends State<AdminBackupRecoveryScreen> {
  final _service = BackupService();

  // ── Backup state ─────────────────────────────────────────────────────────────
  bool _isBackingUp = false;
  String _backupStage = '';
  double _backupProgress = 0.0;
  _BackupResult? _lastBackupResult;

  // ── Restore state ────────────────────────────────────────────────────────────
  bool _isRestoring = false;
  String _restoreStage = '';
  double _restoreProgress = 0.0;
  RestoreReport? _lastRestoreReport;

  // ── Backup ────────────────────────────────────────────────────────────────────

  Future<void> _handleCreateBackup() async {
    setState(() {
      _isBackingUp = true;
      _backupStage = 'Preparing Backup...';
      _backupProgress = 0.0;
      _lastBackupResult = null;
    });

    try {
      final adminEmail = AuthService().currentUser?.email ?? 'Admin';

      // Step 1: Collect data from Firestore
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

      if (mounted) {
        setState(() {
          _backupStage = 'Compressing Backup Package...';
          _backupProgress = 0.97;
        });
      }

      // Step 2: Encode to .hzb string
      final hzbString = package.toHzbString();
      final fileBytes = utf8.encode(hzbString);

      // Step 3: Build filename
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final filename = 'HashZone_Backup_$dateStr.hzb';

      if (mounted) {
        setState(() {
          _backupStage = 'Triggering Download...';
          _backupProgress = 0.99;
        });
      }

      // Step 4: Trigger actual browser download using dart:html
      _triggerBrowserDownload(fileBytes, filename);

      // Step 5: Update UI
      final result = _BackupResult(
        filename: filename,
        version: kHzbVersion,
        createdAt: now,
        totalCollections: package.manifest.totalCollections,
        totalRecords: package.manifest.totalRecords,
        fileSizeBytes: fileBytes.length,
      );

      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _backupStage = 'Download Ready';
          _backupProgress = 1.0;
          _lastBackupResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        _showErrorSnackbar(_safeErrorMessage(e));
      }
    }
  }

  /// Triggers a real browser file download using dart:html Blob + AnchorElement.
  /// This is the ONLY reliable method for Flutter Web file downloads.
  void _triggerBrowserDownload(List<int> bytes, String filename) {
    final blob = html.Blob([bytes], 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';

    html.document.body!.append(anchor);
    anchor.click();

    // Cleanup: revoke URL and remove element after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(url);
      anchor.remove();
    });
  }

  // ── Restore ───────────────────────────────────────────────────────────────────

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
      final package = HzbPackage.fromHzbString(hzbString);
      final analysis = await _service.analyzeBackup(package);

      if (mounted) {
        _showRestoreAnalysisDialog(package, analysis);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Invalid .hzb backup file. ${_safeErrorMessage(e)}');
      }
    }
  }

  void _showRestoreAnalysisDialog(HzbPackage package, RestoreAnalysis analysis) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore Backup',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Backup Version', analysis.manifest.backupVersion),
              _infoRow('Created', analysis.manifest.createdAt.split('T').first),
              _infoRow('Created By', analysis.manifest.createdBy),
              const Divider(height: 20),
              _infoRow('Total Collections', analysis.collectionBreakdown.length.toString()),
              _infoRow('Total Records', analysis.totalRecords.toString()),
              _infoRow('Will Create', analysis.willCreate.toString()),
              _infoRow('Will Update', analysis.willUpdate.toString()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Smart Restore compares by permanent IDs to prevent duplicates. '
                  'A safety backup is created automatically before restoring.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF57C00)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performRestore(package);
            },
            child: Text('RESTORE BACKUP', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(HzbPackage package) async {
    setState(() {
      _isRestoring = true;
      _restoreStage = 'Creating Safety Backup...';
      _restoreProgress = 0.0;
    });

    final adminEmail = AuthService().currentUser?.email ?? 'Admin';
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

    if (mounted) {
      setState(() {
        _isRestoring = false;
        _lastRestoreReport = report;
      });
      _showRestoreReportDialog(report);
    }
  }

  void _showRestoreReportDialog(RestoreReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Restore Report',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24),
        ),
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
              Text(
                'Errors: ${report.errors.length}',
                style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _safeErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied')) return 'Unable to read application data. Check admin permissions.';
    if (msg.contains('unavailable')) return 'Firestore is temporarily unavailable. Please try again.';
    if (msg.contains('empty') || msg.contains('Database layer')) return 'No data found in the database.';
    if (msg.contains('Manifest')) return 'Unable to create the backup package. Manifest error.';
    return 'Backup generation failed. No application data was modified.';
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

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
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
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
                // ── Format info banner ────────────────────────────────────────
                _buildInfoBanner(),
                const SizedBox(height: 24),

                // ── 1. CREATE FULL BACKUP ─────────────────────────────────────
                _buildCard(
                  title: 'FULL DATABASE BACKUP',
                  subtitle:
                      'Generates a structured .hzb package containing all products, customers, orders, payments, and settings. '
                      'Cloudinary file URLs are preserved — binary files remain in Cloudinary.',
                  icon: Icons.cloud_download_outlined,
                  child: _buildBackupSection(),
                ),

                const SizedBox(height: 24),

                // ── 2. RESTORE BACKUP ─────────────────────────────────────────
                _buildCard(
                  title: 'SMART BACKUP RESTORE',
                  subtitle:
                      'Upload a .hzb backup file. Compares permanent IDs to update existing records and create missing ones. '
                      'A safety backup is created automatically before restoring.',
                  icon: Icons.cloud_upload_outlined,
                  child: _buildRestoreSection(),
                ),

                // ── 3. LAST RESTORE SUMMARY ───────────────────────────────────
                if (_lastRestoreReport != null) ...[
                  const SizedBox(height: 24),
                  _buildRestoreSummary(_lastRestoreReport!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Backup format: $kHzbVersion · App: $kAppVersion · Schema: $kDbSchemaVersion · '
              'Cloudinary policy: URLs only (binary files remain in Cloudinary)',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress display
        if (_isBackingUp || _backupProgress > 0) ...[
          _buildProgressDisplay(
            stage: _backupStage,
            progress: _backupProgress,
            color: Colors.black,
          ),
          const SizedBox(height: 16),
        ],

        // Action button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isBackingUp ? null : _handleCreateBackup,
          icon: Icon(_isBackingUp ? Icons.hourglass_top : Icons.download, size: 18),
          label: Text(
            _isBackingUp ? 'GENERATING BACKUP...' : 'CREATE FULL BACKUP (.HZB)',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),

        // Success result card
        if (_lastBackupResult != null && !_isBackingUp) ...[
          const SizedBox(height: 20),
          _buildBackupSuccessCard(_lastBackupResult!),
        ],
      ],
    );
  }

  Widget _buildProgressDisplay({
    required String stage,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFEEEEEE),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                stage,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackupSuccessCard(_BackupResult result) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Text(
                'Backup created successfully.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Filename', result.filename),
          _infoRow('Version', result.version),
          _infoRow('Date & Time', result.createdAt.toLocal().toString().split('.').first),
          _infoRow('Collections', result.totalCollections.toString()),
          _infoRow('Records', result.totalRecords.toString()),
          _infoRow('File Size', _formatBytes(result.fileSizeBytes)),
        ],
      ),
    );
  }

  Widget _buildRestoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isRestoring) ...[
          _buildProgressDisplay(
            stage: _restoreStage,
            progress: _restoreProgress,
            color: const Color(0xFFD32F2F),
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
          label: Text(
            _isRestoring ? 'RESTORING BACKUP...' : 'RESTORE BACKUP (.HZB)',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildRestoreSummary(RestoreReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Restore Summary',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 10),
          _infoRow('Products Created', report.productsCreated.toString()),
          _infoRow('Products Updated', report.productsUpdated.toString()),
          _infoRow('Customers Updated', report.customersUpdated.toString()),
          _infoRow('Orders Updated', report.ordersUpdated.toString()),
          _infoRow('Collections Restored', report.collectionsUpdated.toString()),
          if (report.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${report.errors.length} error(s) during restore.',
                style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Result model ──────────────────────────────────────────────────────────────

class _BackupResult {
  final String filename;
  final String version;
  final DateTime createdAt;
  final int totalCollections;
  final int totalRecords;
  final int fileSizeBytes;

  const _BackupResult({
    required this.filename,
    required this.version,
    required this.createdAt,
    required this.totalCollections,
    required this.totalRecords,
    required this.fileSizeBytes,
  });
}
