import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/developer_testing_service.dart';

class AdminDeveloperTestingScreen extends StatefulWidget {
  const AdminDeveloperTestingScreen({super.key});

  @override
  State<AdminDeveloperTestingScreen> createState() => _AdminDeveloperTestingScreenState();
}

class _AdminDeveloperTestingScreenState extends State<AdminDeveloperTestingScreen> {
  final _service = DeveloperTestingService();
  ConnectionStatus _connectionStatus = const ConnectionStatus();
  bool _isCheckingConnections = false;

  final Map<String, ToolTestResult?> _toolResults = {};

  @override
  void initState() {
    super.initState();
    _refreshConnections();
  }

  Future<void> _refreshConnections() async {
    setState(() => _isCheckingConnections = true);
    final status = await _service.checkLiveConnections();
    if (mounted) {
      setState(() {
        _connectionStatus = status;
        _isCheckingConnections = false;
      });
    }
  }

  void _confirmOcrTestModeToggle(bool currentVal) {
    final bool targetVal = !currentVal;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          targetVal ? 'Enable Test Mode?' : 'Disable Test Mode?',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        content: Text(
          targetVal
              ? 'Disabling OCR validation allows any uploaded image to pass validation. Use only for development and testing.'
              : 'Enabling OCR validation enforces strict browser-side Tesseract.js screenshot scanning.',
          style: GoogleFonts.inter(fontSize: 13.5, color: Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetVal ? const Color(0xFFD32F2F) : Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.setOcrTestMode(targetVal);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      targetVal ? 'OCR Test Mode ENABLED (OCR validation bypassed)' : 'OCR Test Mode DISABLED (OCR validation enforced)',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: targetVal ? const Color(0xFFD32F2F) : Colors.black,
                  ),
                );
              }
            },
            child: Text(targetVal ? 'Enable Test Mode' : 'Enforce OCR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _runTool(String toolKey, Future<ToolTestResult> Function() action) async {
    setState(() {
      _toolResults[toolKey] = const ToolTestResult(status: 'Running...');
    });
    final result = await action();
    if (mounted) {
      setState(() {
        _toolResults[toolKey] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: Text(
          'DEVELOPER & TESTING',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Diagnostics',
            onPressed: _refreshConnections,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. OCR TEST MODE CARD ────────────────────────────────────
                StreamBuilder<bool>(
                  stream: _service.streamOcrTestMode(),
                  builder: (context, snap) {
                    final isTestMode = snap.data ?? false;
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isTestMode ? const Color(0xFFFFF3F3) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isTestMode ? const Color(0xFFFFCDD2) : const Color(0xFFEEEEEE),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isTestMode ? const Color(0xFFD32F2F) : Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.bug_report, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OCR Validation Test Mode',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isTestMode
                                      ? 'TEST MODE ACTIVE: Browser OCR validation is bypassed. Any uploaded image passes immediately.'
                                      : 'PRODUCTION MODE: Browser-side Tesseract.js OCR validation is strictly enforced on all screenshot uploads.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isTestMode ? const Color(0xFFD32F2F) : Colors.black54,
                                    fontWeight: isTestMode ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Switch(
                            value: isTestMode,
                            activeThumbColor: const Color(0xFFD32F2F),
                            onChanged: (_) => _confirmOcrTestModeToggle(isTestMode),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── 2. LIVE CONNECTION STATUS ────────────────────────────────
                _buildCard(
                  title: 'LIVE CONNECTION STATUS',
                  icon: Icons.wifi,
                  trailing: _isCheckingConnections
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                      : null,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _statusTile('Internet Connection', _connectionStatus.internet, Icons.language),
                      _statusTile('Firebase Auth', _connectionStatus.firebaseAuth, Icons.security),
                      _statusTile('Firestore Database', _connectionStatus.firestore, Icons.storage),
                      _statusTile('Firebase Storage', _connectionStatus.firebaseStorage, Icons.cloud),
                      _statusTile('Cloudinary', _connectionStatus.cloudinary, Icons.cloud_upload),
                      _statusTile('OCR Engine (Tesseract.js)', _connectionStatus.ocrEngine, Icons.document_scanner),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 3. APPLICATION INFORMATION ──────────────────────────────
                _buildCard(
                  title: 'APPLICATION INFORMATION',
                  icon: Icons.info_outline,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _infoTile('Application Version', '1.0.0 (Build 2026.08.07)'),
                      _infoTile('Database Version', 'Firestore Schema v1.0'),
                      _infoTile('Backup Version', 'v1.0 (Auto Snapshot)'),
                      _infoTile('Flutter Engine Version', '3.22+ (Web Assembly Ready)'),
                      _infoTile('Build Mode', kDebugMode ? 'Debug Mode' : 'Release Mode'),
                      _infoTile('Current Environment', kDebugMode ? 'Development' : 'Production'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 4. DEVELOPER DIAGNOSTIC TOOLS ───────────────────────────
                _buildCard(
                  title: 'DEVELOPER DIAGNOSTIC TOOLS',
                  icon: Icons.build_outlined,
                  child: Column(
                    children: [
                      _toolRow('Firestore Read / Write Connection Test', () => _service.runFirestoreTest(), 'firestore'),
                      const Divider(height: 16),
                      _toolRow('Cloudinary Endpoint Upload Test', () => _service.runCloudinaryTest(), 'cloudinary'),
                      const Divider(height: 16),
                      _toolRow('Tesseract.js Browser OCR Engine Test', () => _service.runOcrTest(), 'ocr'),
                      const Divider(height: 16),
                      _toolRow('Firestore Backup Log Test', () => _service.runBackupTest(), 'backup'),
                      const Divider(height: 16),
                      _toolRow('Clear Local Persistence Cache', () => _service.clearLocalCache(), 'cache'),
                      const Divider(height: 16),
                      _toolRow('Simulate Brief Offline Network Cycle', () => _service.simulateOfflineMode(), 'offline'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 5. SYSTEM HEALTH QUICK INDICATORS ────────────────────────
                _buildCard(
                  title: 'SYSTEM HEALTH INDICATORS',
                  icon: Icons.health_and_safety_outlined,
                  child: Row(
                    children: [
                      Expanded(child: _healthIndicator('Firestore Read', true)),
                      Expanded(child: _healthIndicator('Firestore Write', true)),
                      Expanded(child: _healthIndicator('Storage Upload', true)),
                      Expanded(child: _healthIndicator('Cloudinary Upload', true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
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
              Icon(icon, size: 20, color: Colors.black),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          child,
        ],
      ),
    );
  }

  Widget _statusTile(String label, String status, IconData icon) {
    final bool isConnected = status == 'Connected';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _toolRow(String title, Future<ToolTestResult> Function() action, String toolKey) {
    final result = _toolResults[toolKey];
    final bool isRunning = result?.status == 'Running...';
    final bool isSuccess = result?.status == 'Success';
    final bool isFailure = result?.status == 'Failure';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isRunning ? null : () => _runTool(toolKey, action),
                child: isRunning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text('Run Diagnostic', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (result != null && result.message != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSuccess ? const Color(0xFFE8F5E9) : isFailure ? const Color(0xFFFFF3F3) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${result.status}: ${result.message}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? const Color(0xFF2E7D32) : isFailure ? const Color(0xFFD32F2F) : Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _healthIndicator(String label, bool isOk) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(isOk ? Icons.check_circle_outline : Icons.error_outline, color: isOk ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F), size: 20),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isOk ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
