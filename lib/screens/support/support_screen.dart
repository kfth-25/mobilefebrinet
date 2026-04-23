import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class SupportScreen extends StatefulWidget {
  final int? initialIssueId;
  const SupportScreen({super.key, this.initialIssueId});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedSubscriptionId;
  String _selectedPriority = 'medium';

  bool _loadingIssues = false;
  bool _loadingSubs = false;
  bool _submitting = false;
  String? _error;

  List<dynamic> _issues = [];
  List<dynamic> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchSubscriptions(),
      _fetchIssues(),
    ]);
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/6281234567890');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _fetchSubscriptions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() {
      _loadingSubs = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/subscriptions?status=active');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as List<dynamic>;
        _subscriptions = raw
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    } catch (_) {
      setState(() {
        _error = 'Gagal memuat data langganan.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSubs = false;
        });
      }
    }
  }

  Future<void> _fetchIssues() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() {
      _loadingIssues = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/issues');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as List<dynamic>;
        _issues = raw
            .whereType<Map<String, dynamic>>()
            .toList();
        final initialId = widget.initialIssueId;
        if (initialId != null) {
          final found = _issues.firstWhere(
            (e) => e is Map<String, dynamic> && e['id'] == initialId,
            orElse: () => {},
          );
          if (found is Map<String, dynamic>) {
            _showIssueDetail(found);
          } else {
            try {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Laporan gangguan #$initialId tidak ditemukan',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            } catch (_) {}
          }
        }
      }
    } catch (_) {
      setState(() {
        _error = 'Gagal memuat laporan gangguan.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingIssues = false;
        });
      }
    }
  }

  Future<void> _submitIssue() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    if (_selectedSubscriptionId == null ||
        _subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      final snackBar = SnackBar(
        content: Text(
          'Lengkapi langganan, subjek, dan deskripsi gangguan.',
          style: GoogleFonts.poppins(),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/issues');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subscription_id': int.tryParse(_selectedSubscriptionId!),
          'subject': _subjectController.text.trim(),
          'description': _descriptionController.text.trim(),
          'priority': _selectedPriority,
        }),
      );

      if (response.statusCode == 201) {
        _subjectController.clear();
        _descriptionController.clear();
        _selectedPriority = 'medium';

        final snackBar = SnackBar(
          content: Text(
            'Laporan gangguan berhasil dikirim.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.primaryColor,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        await _fetchIssues();
      } else {
        setState(() {
          _error = 'Gagal mengirim laporan gangguan.';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Gagal mengirim laporan gangguan.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bantuan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.headset,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Butuh Bantuan?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan fitur laporan gangguan untuk melaporkan kendala internet Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ),
            Text(
              'Buat Laporan Gangguan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_subscriptions.isEmpty && !_loadingSubs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Anda belum memiliki langganan aktif. '
                        'Fitur laporan gangguan tersedia setelah pemasangan layanan.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedSubscriptionId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih langganan',
                      ),
                      items: _subscriptions
                          .map(
                            (sub) => DropdownMenuItem<String>(
                              value: sub['id'].toString(),
                              child: Text(
                                sub['wifi_package']?['name']?.toString() ?? 'Langganan #${sub['id']}',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubscriptionId = value;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Judul laporan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi masalah',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Prioritas',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('Rendah'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Sedang'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('Tinggi'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitIssue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Kirim Laporan',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Kontak Cepat',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: FontAwesomeIcons.whatsapp,
              title: 'Chat WhatsApp',
              subtitle: 'Respon Cepat (Rekomendasi)',
              color: Colors.green,
              onTap: _launchWhatsApp,
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.phone,
              title: 'Call Center',
              subtitle: '021-5566-7788',
              color: Colors.blue,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@febri.net',
              color: Colors.orange,
              onTap: () {},
            ),
            const SizedBox(height: 24),
            Text(
              'Laporan Gangguan Saya',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingIssues)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_issues.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada laporan gangguan.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              Column(
                children: _issues.map((issue) {
                  final priority = issue['priority']?.toString() ?? 'medium';
                  final status = issue['status']?.toString() ?? 'open';
                  return _buildIssueItem(
                    subject: issue['subject']?.toString() ?? '',
                    description: issue['description']?.toString() ?? '',
                    priority: priority,
                    status: status,
                    onTap: () => _showIssueDetail(issue),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            Text(
              'FAQ',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem('Internet lambat, apa yang harus dilakukan?', 'Coba restart modem Anda terlebih dahulu. Matikan selama 5 menit lalu nyalakan kembali.'),
            _buildFaqItem('Bagaimana cara ganti password WiFi?', 'Masuk ke menu Dashboard > Setting > Ubah Password.'),
            _buildFaqItem('Berapa lama proses upgrade paket?', 'Proses upgrade paket biasanya memakan waktu 1x24 jam setelah pembayaran dikonfirmasi.'),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.primaryColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem({
    required String subject,
    required String description,
    required String priority,
    required String status,
    VoidCallback? onTap,
  }) {
    Color priorityColor;
    String priorityLabel;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        priorityLabel = 'Tinggi';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityLabel = 'Rendah';
        break;
      default:
        priorityColor = Colors.orange;
        priorityLabel = 'Sedang';
    }

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'in_progress':
        statusColor = Colors.orange;
        statusLabel = 'Sedang dikerjakan';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusLabel = 'Teratasi';
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusLabel = 'Ditutup';
        break;
      default:
        statusColor = Colors.red;
        statusLabel = 'Terbuka';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Prioritas: $priorityLabel',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  void _showIssueDetail(Map<String, dynamic> issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final id = issue['id']?.toString() ?? '-';
        final subject = issue['subject']?.toString() ?? '-';
        final description = issue['description']?.toString() ?? '-';
        final status = issue['status']?.toString() ?? 'open';
        final priority = issue['priority']?.toString() ?? 'medium';
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Laporan #$id',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subject, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
              Text(description, style: GoogleFonts.poppins(color: Colors.grey[800])),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(label: Text('Status: $status')),
                  const SizedBox(width: 8),
                  Chip(label: Text('Prioritas: $priority')),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Tutup', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
