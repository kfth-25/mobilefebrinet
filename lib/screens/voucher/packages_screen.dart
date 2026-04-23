import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'voucher_payment_screen.dart';
import '../installation/installation_screen.dart';
import '../../widgets/loading_scan_animation.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List<dynamic> _packages = [];
  bool _isLoading = true;
  String? _error;
  String _viewMode = 'modern';
  String _purchaseMode = 'voucher';

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadPurchaseMode();
    _fetchPackages();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _viewMode = prefs.getString('packages_view_mode') ?? 'modern';
    });
  }

  Future<void> _saveViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('packages_view_mode', mode);
  }

  Future<void> _loadPurchaseMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _purchaseMode = prefs.getString('packages_purchase_mode') ?? 'voucher';
    });
  }

  Future<void> _savePurchaseMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('packages_purchase_mode', mode);
  }

  Future<void> _fetchPackages() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthProvider.baseUrl}/packages'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _packages = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal mengambil data paket (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pilih Voucher',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              setState(() {
                _viewMode = v;
              });
              await _saveViewMode(v);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'modern',
                child: Row(
                  children: [
                    Icon(Icons.view_agenda, color: _viewMode == 'modern' ? AppTheme.primaryColor : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Modern', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'voucher',
                child: Row(
                  children: [
                    Icon(Icons.local_activity, color: _viewMode == 'voucher' ? AppTheme.primaryColor : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Voucher', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.tune),
            tooltip: 'Ubah Tampilan',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: GoogleFonts.poppins(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPackages,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text('Voucher', style: GoogleFonts.poppins()),
                        selected: _purchaseMode == 'voucher',
                        onSelected: (_) async {
                          setState(() => _purchaseMode = 'voucher');
                          await _savePurchaseMode('voucher');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Tagihan', style: GoogleFonts.poppins()),
                        selected: _purchaseMode == 'tagihan',
                        onSelected: (_) async {
                          setState(() => _purchaseMode = 'tagihan');
                          await _savePurchaseMode('tagihan');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Hybrid', style: GoogleFonts.poppins()),
                        selected: _purchaseMode == 'hybrid',
                        onSelected: (_) async {
                          setState(() => _purchaseMode = 'hybrid');
                          await _savePurchaseMode('hybrid');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _packages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final pkg = _packages[index];
                final name = pkg['name'] ?? 'Paket';
                final speed = pkg['speed'] ?? '-';
                final dynamic priceRaw = pkg['price'];
                final num basePrice = priceRaw is String
                    ? double.tryParse(priceRaw) ?? 0
                    : (priceRaw is num ? priceRaw : 0);
                final dynamic promoPriceRaw = pkg['promo_price'];
                final num? promoPrice = promoPriceRaw == null
                    ? null
                    : (promoPriceRaw is String
                        ? double.tryParse(promoPriceRaw)
                        : (promoPriceRaw is num ? promoPriceRaw : null));
                final dynamic originalPriceRaw = pkg['original_price'];
                final num? originalPrice = originalPriceRaw == null
                    ? null
                    : (originalPriceRaw is String
                        ? double.tryParse(originalPriceRaw)
                        : (originalPriceRaw is num ? originalPriceRaw : null));
                final String description = (pkg['description'] ?? '').toString();
                final List<String> features = (description.isNotEmpty
                        ? description.split(',')
                        : <String>[])
                    .map((String e) => e.trim())
                    .where((String e) => e.isNotEmpty)
                    .toList();
                final bool isRecommended = pkg['is_recommended'] == true;
                final String? promoLabel =
                    pkg['promo_label'] != null ? pkg['promo_label'].toString() : null;
                DateTime? badgeNewUntil;
                if (pkg['badge_new_until'] != null) {
                  try {
                    badgeNewUntil = DateTime.tryParse(pkg['badge_new_until'].toString());
                  } catch (_) {
                    badgeNewUntil = null;
                  }
                }
                final bool isNew = badgeNewUntil != null &&
                    DateTime.now().isBefore(badgeNewUntil!.add(const Duration(days: 1)));

                String _formatRp(num value) {
                  final int intVal = value.round();
                  final String s = intVal.toString();
                  final StringBuffer buf = StringBuffer();
                  int count = 0;
                  for (int i = s.length - 1; i >= 0; i--) {
                    buf.write(s[i]);
                    count++;
                    if (count % 3 == 0 && i != 0) buf.write('.');
                  }
                  final String rev = buf.toString().split('').reversed.join();
                  return 'Rp $rev/bulan';
                }
                final bool voucherMode = _viewMode == 'voucher';

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: voucherMode ? Colors.grey[50] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: isRecommended
                            ? Border.all(color: AppTheme.secondaryColor, width: 2)
                            : Border.all(color: Colors.transparent),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: voucherMode ? 16 : 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: voucherMode
                                  ? AppTheme.secondaryColor
                                  : (isRecommended ? AppTheme.primaryColor : Colors.white),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(22),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: voucherMode
                                        ? AppTheme.primaryColor
                                        : (isRecommended ? Colors.white : AppTheme.primaryColor),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  speed,
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: voucherMode
                                        ? Colors.white
                                        : (isRecommended ? AppTheme.secondaryColor : AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (voucherMode)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  22,
                                  (i) => Container(
                                    width: 8,
                                    height: 2,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                ...features.map((feature) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: voucherMode
                                                ? AppTheme.primaryColor
                                                : (isRecommended ? AppTheme.secondaryColor : Colors.green),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              feature,
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 24),
                                Divider(color: Colors.grey[200]),
                                const SizedBox(height: 16),
                                Builder(builder: (_) {
                                  final bool hasPromo = promoPrice != null && promoPrice! > 0;
                                  final num showBase = hasPromo ? (originalPrice ?? basePrice) : basePrice;
                                  return Column(
                                    children: [
                                      if (hasPromo)
                                        Text(
                                          _formatRp(showBase),
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatRp(hasPromo ? promoPrice! : basePrice),
                                        style: GoogleFonts.poppins(
                                          color: voucherMode ? AppTheme.secondaryColor : AppTheme.primaryColor,
                                          fontSize: voucherMode ? 32 : 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 24),
                                Builder(builder: (_) {
                                  if (_purchaseMode == 'voucher') {
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => VoucherPaymentScreen(
                                                package: pkg,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: voucherMode
                                              ? AppTheme.primaryColor
                                              : (isRecommended ? AppTheme.secondaryColor : AppTheme.primaryColor),
                                          foregroundColor: voucherMode
                                              ? Colors.white
                                              : (isRecommended ? AppTheme.primaryColor : Colors.white),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: Text(
                                          'Pilih Voucher',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  } else if (_purchaseMode == 'tagihan') {
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          final id = pkg['id']?.toString();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => InstallationScreen(
                                                preselectedPackageId: id,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: Text(
                                          'Langganan Sekarang',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => VoucherPaymentScreen(
                                                    package: pkg,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                            ),
                                            child: Text(
                                              'Voucher',
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              final id = pkg['id']?.toString();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => InstallationScreen(
                                                    preselectedPackageId: id,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                            ),
                                            child: Text(
                                              'Langganan',
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          delay: Duration(milliseconds: index * 100),
                          duration: 500.ms,
                        ),
                    if (isRecommended)
                      Positioned(
                        top: -12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'REKOMENDASI',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (promoLabel != null || (promoPrice != null && promoPrice! > 0))
                      Positioned(
                        top: -10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            promoLabel ?? 'PROMO',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    if (isNew)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigoAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'BARU',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
                    },
                  ),
                ),
              ],
            ),
          if (!_isLoading && _error == null && _packages.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum ada paket ditampilkan', style: GoogleFonts.poppins()),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _fetchPackages, child: const Text('Muat Ulang')),
                ],
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: LoadingScanAnimation(
                    size: 120,
                    label: 'Mengambil data paket…',
                  ),
                ),
              ),
            ),
        ],
      )
    );
  }
}
