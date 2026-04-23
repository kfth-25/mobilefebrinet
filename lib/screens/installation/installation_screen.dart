import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/grid_background_painter.dart';
import '../home/dashboard_screen.dart'; // For navigation back to home
import './technician_selection_screen.dart';

class InstallationScreen extends StatefulWidget {
  final String? preselectedPackageId;
  const InstallationScreen({super.key, this.preselectedPackageId});

  @override
  State<InstallationScreen> createState() => _InstallationScreenState();
}

class _InstallationScreenState extends State<InstallationScreen> {
  int _currentStep = 1;
  bool _isSuccess = false;
  String _regNumber = '';

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ktpController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _mapLinkController = TextEditingController();
  String? _selectedKelurahan;
  Map<String, dynamic>? _selectedTechnician;

  // Selection State
  late String _selectedPackageId;
  String _selectedPaymentId = 'febripay';

  final List<String> _kelurahanList = [
    'Argasunya',
    'Harjamukti',
    'Kecapi',
    'Larangan',
    'Kalijaga',
    'Sunyaragi',
  ];

  final List<Map<String, dynamic>> _packages = [
    {
      'id': 'starter',
      'name': 'Starter Home',
      'speed': '20 Mbps',
      'price': 'Rp 90rb',
      'price_full': 'Rp 90.000',
      'desc': '1-2 device · browsing & HD',
      'badge': null,
    },
    {
      'id': 'family',
      'name': 'Family Entertainment',
      'speed': '50 Mbps',
      'price': 'Rp 150rb',
      'price_full': 'Rp 150.000',
      'desc': '4-6 device · 4K + gaming',
      'badge': '⭐',
    },
    {
      'id': 'turbo',
      'name': 'Turbo',
      'speed': '100 Mbps',
      'price': 'Rp 200rb',
      'price_full': 'Rp 200.000',
      'desc': '10+ device · bisnis',
      'badge': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedPackageId = widget.preselectedPackageId ?? 'family';
    // Pre-fill name if available
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      _nameController.text = auth.user!['name'] ?? '';
      _emailController.text = auth.user!['email'] ?? '';
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitForm() async {
    final payload = {
      'wifi_package_id': _selectedPackageId,
      'installation_address': '${_addressController.text}, RT ${_rtController.text}/RW ${_rwController.text}, Kel ${_selectedKelurahan ?? ''}',
      'full_name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'technician_id': _selectedTechnician?['id'],
      'map_link': _mapLinkController.text.isNotEmpty ? _mapLinkController.text : null,
      'notes': 'KTP: ${_ktpController.text} | Patokan: ${_landmarkController.text}',
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.11.158:8000/api/register-installation'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _regNumber = data['registration_code'] ?? data['id']?.toString() ?? 'BERHASIL';
          _isSuccess = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pendaftaran. Silakan coba lagi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan. Cek koneksi Anda.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user has active subscription, we might want to show a different screen or blocking dialog.
    // But for "Pasang Baru", it might be allowed for adding a second line or upgrade.
    // For now, adhering to the UI request.

    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      body: Stack(
        children: [
          // Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1221),
                    Color(0xFF162033),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Header
              _buildHeader(),
              
              // Body
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (_currentStep == 1) _buildStep1(),
                          if (_currentStep == 2) _buildStep2(),
                          if (_currentStep == 3) _buildStep3(),
                          const SizedBox(height: 24),
                          // Navigation Buttons
                          Row(
                            children: [
                              if (_currentStep > 1)
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: OutlinedButton(
                                      onPressed: _prevStep,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: BorderSide(color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        '← Kembali',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _currentStep == 3 ? 'Kirim Pendaftaran ✓' : 'Lanjut →',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAYANAN BARU',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Pasang Baru',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ESTIMASI',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                      ),
                    ),
                    Text(
                      '1-3 hari',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Langkah $_currentStep dari 3',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index < _currentStep 
                        ? AppTheme.primaryColor 
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // STEP 1: Data Diri
  Widget _buildStep1() {
    return Column(
      children: [
        _buildFormCard(
          title: 'Data Diri',
          icon: Icons.person_outline,
          subtitle: 'Isi data lengkap untuk pendaftaran layanan baru',
          children: [
            _buildInputLabel('Nama Lengkap'),
            _buildTextField(controller: _nameController, hint: 'Contoh: Budi Santoso'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('No. HP / WhatsApp'),
                      _buildTextField(controller: _phoneController, hint: '08xx-xxxx', keyboardType: TextInputType.phone),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Nomor KTP'),
                      _buildTextField(controller: _ktpController, hint: '16 digit', keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputLabel('Email'),
            _buildTextField(controller: _emailController, hint: 'email@contoh.com', keyboardType: TextInputType.emailAddress),
          ],
        ),
        const SizedBox(height: 20),
        _buildFormCard(
          title: 'Alamat Pemasangan',
          icon: Icons.home_outlined,
          subtitle: 'Alamat tempat WiFi akan dipasang',
          children: [
            _buildInputLabel('Kelurahan / Desa'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedKelurahan,
                  hint: Text('--- Pilih kelurahan --', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  items: _kelurahanList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedKelurahan = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('RT'),
                      _buildTextField(controller: _rtController, hint: '00', keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('RW'),
                      _buildTextField(controller: _rwController, hint: '00', keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputLabel('Alamat Lengkap'),
            _buildTextField(controller: _addressController, hint: 'Jl. nama jalan, no. rumah...'),
            const SizedBox(height: 16),
            _buildInputLabel('Patokan (opsional)'),
            _buildTextField(controller: _landmarkController, hint: 'Contoh: Dekat masjid Al-Falah'),
            const SizedBox(height: 16),
            _buildInputLabel('Link Google Maps'),
            _buildTextField(controller: _mapLinkController, hint: 'https://maps.app.goo.gl/...', keyboardType: TextInputType.url),
            const SizedBox(height: 16),
            _buildInputLabel('Pilih Teknisi (opsional)'),
            InkWell(
              onTap: () async {
                final selected = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(builder: (_) => TechnicianSelectionScreen()),
                );
                if (selected != null) {
                  setState(() {
                    _selectedTechnician = selected;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTechnician != null 
                          ? _selectedTechnician!['name'] 
                          : 'Pilih teknisi pilihan Anda...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _selectedTechnician != null ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2: Pilih Paket
  Widget _buildStep2() {
    return Column(
      children: [
        _buildFormCard(
          title: 'Pilih Paket',
          icon: Icons.bolt,
          subtitle: 'Pilih paket yang sesuai kebutuhanmu',
          children: _packages.map((pkg) {
            final isSelected = _selectedPackageId == pkg['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedPackageId = pkg['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : const Color(0xFFE4E9F4),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                          width: isSelected ? 6 : 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                pkg['name'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: const Color(0xFF0A0F1E),
                                ),
                              ),
                              if (pkg['badge'] != null) ...[
                                const SizedBox(width: 6),
                                Text(pkg['badge'], style: const TextStyle(fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pkg['desc'],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          pkg['price'],
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '/bulan',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildFormCard(
          title: 'Metode Pembayaran',
          icon: Icons.lock_outline,
          subtitle: 'Biaya pasang awal + bulan pertama',
          children: [
            _buildPaymentOption('febripay', 'FebriPay', 'Saldo: Rp 85.500'),
            _buildPaymentOption('qris', 'Transfer / QRIS', 'Konfirmasi manual'),
            _buildPaymentOption('cash', 'Bayar ke Teknisi', 'Tunai saat pemasangan'),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String id, String title, String subtitle) {
    final isSelected = _selectedPaymentId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE4E9F4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF0A0F1E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Konfirmasi
  Widget _buildStep3() {
    final selectedPkg = _packages.firstWhere((p) => p['id'] == _selectedPackageId);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1221),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RINGKASAN PESANAN',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Nama', _nameController.text.isNotEmpty ? _nameController.text : '-'),
              _buildSummaryRow('No. HP', _phoneController.text.isNotEmpty ? _phoneController.text : '-'),
              _buildSummaryRow('Kelurahan', _selectedKelurahan ?? '-'),
              _buildSummaryRow('Paket', selectedPkg['name'] + ' ' + selectedPkg['speed']),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Bayar',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    selectedPkg['price_full'],
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildFormCard(
          title: 'Proses Pemasangan',
          icon: Icons.timeline,
          subtitle: 'Estimasi selesai 1–3 hari kerja',
          children: [
            _buildTimelineItem(
              icon: Icons.check,
              color: const Color(0xFF10B981),
              title: 'Pendaftaran Diterima',
              desc: 'Data masuk sistem, sedang diproses.',
              isFirst: true,
            ),
            _buildTimelineItem(
              icon: Icons.home_work_outlined,
              color: const Color(0xFF3B82F6),
              title: 'Survey Lokasi',
              desc: 'Tim kami menghubungimu untuk konfirmasi.',
              tag: 'Hari ke-1',
            ),
            _buildTimelineItem(
              icon: Icons.build_outlined,
              color: const Color(0xFFF59E0B),
              title: 'Pemasangan',
              desc: 'Teknisi datang dan pasang perangkat WiFi.',
              tag: 'Hari ke-2',
            ),
            _buildTimelineItem(
              icon: Icons.wifi,
              color: AppTheme.primaryColor,
              title: 'WiFi Aktif 🎉',
              desc: 'Internet siap! Akun Febri.net langsung aktif.',
              tag: 'Hari ke-3',
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    String? tag,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF0A0F1E),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGETS
  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A0F1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final selectedPkg = _packages.firstWhere((p) => p['id'] == _selectedPackageId);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NO. REGISTRASI',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _regNumber,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: AppTheme.primaryColor, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Pendaftaran Berhasil!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tim Febri.net akan menghubungi kamu dalam 1×24 jam untuk konfirmasi survey & jadwal pemasangan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Nama', _nameController.text),
                    _buildSummaryRow('Paket', selectedPkg['name']),
                    _buildSummaryRow('Estimasi Aktif', '1-3 hari kerja'),
                    _buildSummaryRow('CS WhatsApp', '0812-3456-7000'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(), // Back to Home
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B1221),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Kembali ke Home',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
