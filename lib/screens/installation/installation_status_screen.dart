import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'installation_screen.dart';
import 'installation_detail_screen.dart';

class InstallationStatusScreen extends StatefulWidget {
  final int? initialSubscriptionId;
  const InstallationStatusScreen({super.key, this.initialSubscriptionId});

  @override
  State<InstallationStatusScreen> createState() =>
      _InstallationStatusScreenState();
}

class _InstallationStatusScreenState extends State<InstallationStatusScreen> {
  Map<String, dynamic>? _request;
  Map<String, dynamic>? _activeSubscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _loading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('installation_requests');
      if (raw == null || raw.isEmpty) {
        setState(() {
          _request = null;
          _loading = false;
        });
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        setState(() {
          _request = null;
          _loading = false;
        });
        return;
      }

      List<Map<String, dynamic>> list = decoded
          .whereType<Map>()
          .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
          .toList();

      Map<String, dynamic>? candidate;

      if (user != null) {
        final userId = user['id'];
        final userEmail = user['email'];

        final filtered = list.where((item) {
          if (userId != null &&
              item['user_id'] != null &&
              item['user_id'] == userId) {
            return true;
          }
          if (userEmail != null &&
              item['user_email'] != null &&
              item['user_email'] == userEmail) {
            return true;
          }
          return false;
        }).toList();

        if (filtered.isNotEmpty) {
          candidate = filtered.last;
        } else {
          final anyTagged = list.any(
              (item) => item['user_id'] != null || item['user_email'] != null);
          if (!anyTagged) {
            candidate = list.last;
          }
        }
      } else {
        candidate = list.last;
      }

      setState(() {
        _request = candidate;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _request = null;
        _loading = false;
      });
    }

    await _loadActiveSubscription();
  }

  Future<void> _loadActiveSubscription() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

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
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded.whereType<Map<String, dynamic>>().toList();
          if (list.isNotEmpty && mounted) {
            setState(() {
              _activeSubscription = list.first;
            });
            final initId = widget.initialSubscriptionId;
            if (initId != null) {
              try {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Membuka status langganan #$initId',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Status Pemasangan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _activeSubscription != null
              ? _buildActiveInstalledState(context)
              : _request == null
                  ? _buildEmptyState(context)
                  : _buildContent(context),
    );
  }

  Widget _buildActiveInstalledState(BuildContext context) {
    final subscription = _activeSubscription!;
    final package = subscription['wifi_package'] as Map<String, dynamic>?;

    final packageName = package?['name']?.toString() ?? '-';
    final speed = package?['speed']?.toString();
    final address = subscription['installation_address']?.toString() ?? '-';

    DateTime? activatedAt;
    final activatedRaw = subscription['activated_at']?.toString();
    if (activatedRaw != null && activatedRaw.isNotEmpty) {
      try {
        activatedAt = DateTime.parse(activatedRaw);
      } catch (_) {
        activatedAt = null;
      }
    }

    final activatedLabel = activatedAt != null
        ? '${activatedAt.day} ${_monthLabel(activatedAt.month)} ${activatedAt.year}'
        : '-';

    DateTime? expiresAt;
    final expiresRaw = subscription['expires_at']?.toString() ??
        subscription['expired_at']?.toString();
    if (expiresRaw != null && expiresRaw.isNotEmpty) {
      try {
        expiresAt = DateTime.parse(expiresRaw);
      } catch (_) {
        expiresAt = null;
      }
    } else if (activatedAt != null) {
      expiresAt = activatedAt.add(const Duration(days: 30));
    }

    final expiresLabel = expiresAt != null
        ? '${expiresAt.day} ${_monthLabel(expiresAt.month)} ${expiresAt.year}'
        : '-';

    String remainingLabel = '-';
    if (expiresAt != null) {
      final diff = expiresAt.difference(DateTime.now()).inDays;
      if (diff > 0) {
        remainingLabel = '± $diff hari lagi';
      } else if (diff == 0) {
        remainingLabel = 'Berakhir hari ini';
      } else {
        remainingLabel = 'Melebihi masa aktif';
      }
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + bottomInset + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pemasangan Selesai',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Akun ini sudah memiliki pemasangan WiFi yang aktif. Detail ringkasan pemasangan dapat Anda lihat di bawah.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ringkasan Pemasangan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7E9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Layanan Aktif',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  icon: Icons.wifi,
                  label: 'Voucher Internet',
                  value: speed != null && speed.isNotEmpty
                      ? '$packageName • $speed'
                      : packageName,
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat Pemasangan',
                  value: address,
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Aktif Sejak',
                  value: activatedLabel,
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  icon: Icons.event_available_outlined,
                  label: 'Berlaku Hingga',
                  value: expiresLabel,
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  icon: Icons.timer_outlined,
                  label: 'Sisa Masa Aktif',
                  value: remainingLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jika Anda ingin memindahkan lokasi pemasangan atau melakukan perubahan layanan, silakan hubungi admin atau gunakan menu Bantuan.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_outlined,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum Ada Permohonan Pemasangan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajukan pemasangan WiFi terlebih dahulu melalui menu Pemasangan untuk melihat progres di sini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstallationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ajukan Pemasangan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final request = _request!;

    DateTime? created;
    try {
      created = DateTime.parse(request['created_at'].toString());
    } catch (_) {
      created = null;
    }

    final createdLabel = created != null
        ? '${created.day} ${_monthLabel(created.month)} ${created.year}, '
            '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}'
        : '-';

    DateTime? eta;
    if (created != null) {
      eta = created.add(const Duration(days: 2));
    }
    final etaLabel = eta != null
        ? '${eta.day} ${_monthLabel(eta.month)} ${eta.year}'
        : '-';

    final statusSteps = [
      {
        'key': 'submitted',
        'label': 'Permohonan Diterima',
        'description':
            'Permohonan pemasangan WiFi Anda sudah kami terima dan tercatat di sistem.',
      },
      {
        'key': 'scheduled',
        'label': 'Dijadwalkan',
        'description':
            'Tim kami sedang menyusun jadwal kunjungan teknisi ke lokasi Anda.',
      },
      {
        'key': 'installing',
        'label': 'Teknisi Dalam Pemasangan',
        'description':
            'Teknisi sedang menuju lokasi atau dalam proses pemasangan perangkat.',
      },
      {
        'key': 'done',
        'label': 'Pemasangan Selesai',
        'description':
            'Pemasangan selesai dan layanan internet Anda sudah aktif digunakan.',
      },
    ];

    final currentStatus = request['status']?.toString() ?? 'pending';
    final progressIndex = currentStatus == 'pending'
        ? 0
        : currentStatus == 'scheduled'
            ? 1
            : currentStatus == 'installing'
                ? 2
                : 3;

    final photoPath = request['photo_path']?.toString();
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final address = request['address']?.toString() ?? '-';
    final packageName = request['name']?.toString() ?? '';
    final schedule = request['schedule']?.toString() ?? '-';
    final mapLink = request['map_link']?.toString();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + bottomInset + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres Pemasangan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau tahapan pemasangan mulai dari permohonan diterima hingga layanan aktif.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          if (hasPhoto)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Text(
                          'Foto lokasi tidak dapat ditampilkan',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Permohonan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  icon: Icons.wifi,
                  label: 'Voucher',
                  value: packageName.isEmpty ? '-' : packageName,
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: address,
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Preferensi Jadwal',
                  value: schedule.isEmpty ? '-' : schedule,
                ),
                if (mapLink != null && mapLink.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _openMap(mapLink),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(
                      'Buka di Maps',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InstallationDetailScreen(request: request),
                        ),
                      );
                    },
                    child: Text(
                      'Lihat Detail Pesanan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nomor Permohonan',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${request['id']}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(currentStatus),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(
                    statusSteps.length,
                    (index) {
                      final step = statusSteps[index];
                      final bool isActive = index == progressIndex;
                      final bool isCompleted = index < progressIndex;
                      return _buildStepItem(
                        index: index,
                        label: step['label'].toString(),
                        description: step['description'].toString(),
                        isActive: isActive,
                        isCompleted: isCompleted,
                        isLast: index == statusSteps.length - 1,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        title: 'Jadwal Mulai',
                        value: createdLabel,
                        icon: Icons.schedule,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoTile(
                        title: 'Perkiraan Selesai',
                        value: etaLabel,
                        icon: Icons.schedule_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required String label,
    required String description,
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isActive
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isActive
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: index < (isCompleted ? index + 1 : index + 1)
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : 16,
              top: 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppTheme.primaryColor
                        : Colors.grey.shade900,
                  ),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch');
      }
    } catch (_) {}
  }

  String _monthLabel(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    if (month < 1 || month > 12) return '';
    return names[month];
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Dijadwalkan';
      case 'installing':
        return 'Dalam Pemasangan';
      case 'done':
        return 'Selesai / Aktif';
      default:
        return 'Menunggu Proses';
    }
  }
}
