import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_scan_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../billing/billing_screen.dart';

class VoucherPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> package;

  const VoucherPaymentScreen({super.key, required this.package});

  @override
  State<VoucherPaymentScreen> createState() => _VoucherPaymentScreenState();
}

class _VoucherPaymentScreenState extends State<VoucherPaymentScreen> {
  bool _isProcessing = false;
  String? _voucherCode;
  bool _savedLocally = false;
  String _selectedMethod = 'bank_transfer';

  Future<void> _saveVoucherLocally() async {
    if (_voucherCode == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_vouchers');
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw) as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }
      final item = {
        'code': _voucherCode,
        'package': widget.package['name']?.toString(),
        'speed': widget.package['speed']?.toString(),
        'price': widget.package['price'],
        'saved_at': DateTime.now().toIso8601String(),
      };
      list.insert(0, item);
      if (list.length > 10) {
        list = list.sublist(0, 10);
      }
      await prefs.setString('saved_vouchers', jsonEncode(list));
      setState(() {
        _savedLocally = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode voucher disimpan.')),
        );
      }
    } catch (_) {}
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/voucher-transactions');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'wifi_package_id': widget.package['id'],
          'payment_method': _selectedMethod,
        }),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _voucherCode = decoded['voucher_code'];
          _isProcessing = false;
        });
        await _saveVoucherLocally();
      } else if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesi telah berakhir. Silakan login kembali.')),
          );
          // Optional: navigate to login screen if needed
        }
        setState(() {
          _isProcessing = false;
        });
      } else {
        if (mounted) {
          // Log response for debugging
          print('Payment failed: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memproses pembayaran (${response.statusCode}). Silakan coba lagi.')),
          );
        }
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Payment error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pembayaran Voucher',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _voucherCode != null ? _buildSuccessState() : _buildPaymentState(),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.08),
                child: Center(
                  child: LoadingScanAnimation(
                    size: 90,
                    label: 'Memproses Pembayaran…',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentState() {
    final pkg = widget.package;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
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
              Text(
                'Ringkasan Pesanan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paket:',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  Text(
                    pkg['name']?.toString() ?? '-',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kecepatan:',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  Text(
                    pkg['speed']?.toString() ?? '-',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Bayar:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rp ${pkg['price'] ?? 0}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Metode Pembayaran',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption('Transfer Bank', Icons.account_balance, 'bank_transfer'),
        _buildPaymentOption('E-Wallet (OVO, GoPay, Dana)', Icons.wallet, 'ewallet'),
        _buildPaymentOption('Kartu Kredit', Icons.credit_card, 'credit_card'),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingScanAnimation(size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Memproses…',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Bayar Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String key) {
    final isSelected = _selectedMethod == key;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedMethod = key;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
            border: Border.all(
              color: isSelected ? AppTheme.secondaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppTheme.secondaryColor : AppTheme.primaryColor),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
                ),
              ),
              const Spacer(),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppTheme.secondaryColor : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 100,
        ),
        const SizedBox(height: 24),
        Text(
          'Pembayaran Berhasil!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Voucher Anda telah aktif. Gunakan kode di bawah ini untuk menghubungkan perangkat Anda.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text(
                'KODE VOUCHER',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _voucherCode!,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _savedLocally ? null : _saveVoucherLocally,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(
                      _savedLocally ? 'Tersimpan' : 'Simpan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _voucherCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode disalin ke clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(
                      'Salin',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to packages
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Selesai',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BillingScreen()),
                  );
                },
                child: Text('Voucher Tersimpan'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
