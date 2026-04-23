import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class TaskDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const TaskDetailScreen({super.key, required this.job});

  Future<void> _openMap() async {
    final url = job['map_link'];
    if (url == null || url.isEmpty) return;
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPemasangan = job['type'] == 'Pemasangan';
    final data = job['originalData'] ?? {};

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B1220),
                    Color(0xFF102536),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isPemasangan ? const Color(0xFF3A5BFA) : Colors.orange).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          isPemasangan ? 'PEMASANGAN' : 'PERBAIKAN',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TIKET ID: ${job['id']}',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Detail Tugas',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Informasi Pelanggan',
                    icon: Icons.person_rounded,
                    items: [
                      _buildInfoRow('Nama', job['customer']),
                      _buildInfoRow('Telepon', job['phone']),
                      _buildInfoRow('Alamat', job['address']),
                    ],
                  ),
                  
                  if (job['map_link'] != null && job['map_link'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openMap,
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: Text('Buka di Google Maps', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4C9).withOpacity(0.1),
                          foregroundColor: const Color(0xFF00D4C9),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF00D4C9), width: 1),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 28),
                  
                  _buildSection(
                    title: isPemasangan ? 'Detail Pemasangan' : 'Detail Gangguan',
                    icon: isPemasangan ? Icons.wifi_rounded : Icons.build_circle_rounded,
                    items: [
                      if (isPemasangan) _buildInfoRow('Paket WiFi', job['package'] ?? '-'),
                      if (!isPemasangan) _buildInfoRow('Subjek', job['issue'] ?? '-'),
                      _buildInfoRow('Tgl Pengajuan', job['date']),
                      _buildInfoRow('Status Tiket', job['status'] == 'in_progress' ? 'Sedang Dikerjakan' : 'Terbuka'),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  
                  Text(
                    'Catatan Pelanggan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      data['notes'] != null && data['notes'].toString().isNotEmpty ? data['notes'] : 'Tidak ada catatan tambahan dari pelanggan.',
                      style: GoogleFonts.poppins(color: const Color(0xFF1E293B), height: 1.5, fontSize: 14),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (job['status'] == 'pending' || job['status'] == 'Terbuka')
                    _buildActionButton(
                      label: 'MULAI KERJAKAN',
                      color: AppTheme.primaryColor,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status diperbarui menjadi dikerjakan.')),
                        );
                      },
                    ),
                  if (job['status'] == 'in_progress' || job['status'] == 'Dikerjakan')
                    _buildActionButton(
                      label: 'SELESAIKAN TUGAS',
                      color: const Color(0xFF10B981),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tugas telah diselesaikan.')),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: color.withOpacity(0.3),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
