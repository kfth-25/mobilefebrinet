import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';
import 'technician_selection_screen.dart';

class InstallationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> request;

  const InstallationDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final createdAt = request['created_at']?.toString();
    DateTime? created;
    try {
      if (createdAt != null) {
        created = DateTime.parse(createdAt);
      }
    } catch (_) {
      created = null;
    }

    final createdLabel = created != null
        ? '${created.day.toString().padLeft(2, '0')} '
            '${_monthName(created.month)} ${created.year}, '
            '${created.hour.toString().padLeft(2, '0')}:'
            '${created.minute.toString().padLeft(2, '0')}'
        : '-';

    final status = request['status']?.toString() ?? 'pending';
    final mapLink = request['map_link']?.toString();
    final photoPath = request['photo_path']?.toString();
    final canChooseTechnician =
        status == 'pending' || status == 'scheduled' || status == 'installing';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Pesanan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Informasi Pemohon',
              children: [
                _buildRow('Nama', request['name']?.toString() ?? '-'),
                _buildRow('Email', request['email']?.toString() ?? '-'),
                _buildRow('No. HP', request['phone']?.toString() ?? '-'),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Detail Pemasangan',
              children: [
                _buildRow('Nomor Permohonan', '#${request['id']}'),
                _buildRow(
                    'Status', _statusLabel(status), valueColor: Colors.orange),
                _buildRow('Voucher', request['name']?.toString() ?? '-'),
                _buildRow('Alamat',
                    request['address']?.toString() ?? '-', multiLine: true),
                _buildRow('Jadwal Preferensi',
                    request['schedule']?.toString() ?? '-'),
                _buildRow(
                    'Catatan', request['notes']?.toString() ?? '-', multiLine: true),
                _buildRow('Dibuat Pada', createdLabel),
              ],
            ),
            if (mapLink != null && mapLink.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Lokasi di Maps',
                children: [
                  Text(
                    mapLink,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMap(mapLink),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(
                        'Buka di Google Maps',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (photoPath != null && photoPath.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Foto Lokasi',
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                              'Foto tidak dapat ditampilkan.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Foto ini membantu teknisi menemukan lokasi rumah atau titik pemasangan dengan lebih cepat.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            if (canChooseTechnician) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openTechnicianSelection(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.engineering_outlined),
                  label: Text(
                    'Pilih Teknisi',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openTechnicianSelection(BuildContext context) async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => TechnicianSelectionScreen(
          request: request,
        ),
      ),
    );

    if (selected != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        final name = selected['name']?.toString() ?? '';
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              name.isNotEmpty
                  ? 'Teknisi $name telah dipilih sebagai preferensi Anda.'
                  : 'Teknisi berhasil dipilih sebagai preferensi Anda.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool multiLine = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
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

  String _monthName(int month) {
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
}
