import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../billing/_topup_widgets.dart';
import '../network/speed_test_screen.dart';
import '../support/support_screen.dart';
import '../installation/installation_screen.dart';
import '../installation/installation_status_screen.dart';
import '../network/wifi_scanner_screen.dart';
import '../network/nearby_wifi_screen.dart';
import '../billing/billing_screen.dart';
import '../community/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/notification_screen.dart';
import '../../services/fcm_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _activeSubscription;
  Map<String, dynamic>? _voucherSummary;
  List<Map<String, dynamic>> _recentNotifs = [];
  int? _wifiDevicesCount;
  bool _wifiCountLoading = false;
  String? _wifiCountError;
  int? _walletBalance; // dalam rupiah

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveSubscription();
      _loadVoucherSummary();
      _loadRecentNotifications();
      _loadWifiCountFromPrefs().then((found) {
        if (!found) {
          _peekWifiDevicesCount();
        }
      });
      _loadWalletBalanceFromPrefs();
    });
  }

  Future<void> _loadActiveSubscription() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    try {
      final uri =
          Uri.parse('${AuthProvider.baseUrl}/subscriptions?status=active');
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
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadWalletBalanceFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bal = prefs.getInt('febripay_balance') ?? 85500;
      if (mounted) {
        setState(() {
          _walletBalance = bal;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveWalletBalanceToPrefs(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('febripay_balance', value);
    } catch (_) {}
  }

  void _showRestrictionDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Akses Dibatasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        content: Text(
          'Anda harus melakukan pemasangan WiFi terlebih dahulu sebelum dapat menggunakan fitur $feature.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InstallationScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Pasang Sekarang',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showTopUpSheet() {
    if (_activeSubscription == null) {
      _showRestrictionDialog('Top Up Saldo');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        int selected = 0;
        return StatefulBuilder(builder: (ctx, setLocal) {
          void pick(int amt) {
            setLocal(() => selected = amt);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Top Up Saldo',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    TopUpMethod(icon: Icons.qr_code, label: 'QRIS'),
                    TopUpMethod(icon: Icons.account_balance, label: 'Virtual\nAccount'),
                    TopUpMethod(icon: Icons.account_balance_wallet, label: 'Transfer\nBank'),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nominal Top Up',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    selected == 0 ? 'Rp 0' : _formatRupiah(selected),
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    NominalChip(label: 'Rp 20rb', onTap: () => pick(20000), selected: selected == 20000),
                    NominalChip(label: 'Rp 50rb', onTap: () => pick(50000), selected: selected == 50000),
                    NominalChip(label: 'Rp 100rb', onTap: () => pick(100000), selected: selected == 100000),
                    NominalChip(label: 'Rp 200rb', onTap: () => pick(200000), selected: selected == 200000),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected == 0
                        ? null
                        : () {
                            final current = _walletBalance ?? 0;
                            final next = current + selected;
                            setState(() => _walletBalance = next);
                            _saveWalletBalanceToPrefs(next);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Top up berhasil: ${_formatRupiah(selected)}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4A0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Lanjutkan Top Up', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  String _formatRupiah(int nominal) {
    final s = nominal.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final rev = s.length - i;
      buf.write(s[i]);
      if (rev > 1 && rev % 3 == 1) buf.write('.');
    }
    return 'Rp $buf';
  }

  Future<void> _loadVoucherSummary() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    try {
      final uri = Uri.parse(
          '${AuthProvider.baseUrl}/voucher-transactions?summary=1');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && mounted) {
          setState(() {
            _voucherSummary = decoded;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRecentNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('recent_notifications');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
          if (mounted) {
            setState(() {
              _recentNotifs = list;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<bool> _loadWifiCountFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('wifi_last_devices_count');
      if (count != null) {
        if (mounted) {
          setState(() {
            _wifiDevicesCount = count;
            _wifiCountLoading = false;
          });
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _peekWifiDevicesCount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;
    setState(() {
      _wifiCountLoading = true;
      _wifiCountError = null;
    });
    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/network-scans');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as Map<String, dynamic>;
        final devices = (raw['devices'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .toList();
        setState(() {
          _wifiDevicesCount = devices.length;
        });
      } else {
        setState(() {
          _wifiDevicesCount = null;
          _wifiCountError = 'Gagal memuat';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _wifiDevicesCount = null;
        _wifiCountError = 'Gagal memuat';
      });
    } finally {
      if (mounted) {
        setState(() {
          _wifiCountLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    String packageName = 'Family Entertainment';
    String speedLabel = '50 Mbps';
    String expiresLabel = '-';
    String remainingLabel = '-';

    final subscription = _activeSubscription;
    final voucherSummary = _voucherSummary;
    if (subscription != null) {
      final package = subscription['wifi_package'] as Map<String, dynamic>?;
      final name = package?['name']?.toString();
      final speed = package?['speed']?.toString();

      if (name != null && name.isNotEmpty) {
        packageName = name;
      }
      if (speed != null && speed.isNotEmpty) {
        speedLabel = speed;
      }

      DateTime? activatedAt;
      final activatedRaw = subscription['activated_at']?.toString();
      if (activatedRaw != null && activatedRaw.isNotEmpty) {
        try {
          activatedAt = DateTime.parse(activatedRaw);
        } catch (_) {
          activatedAt = null;
        }
      }

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

      if (expiresAt != null) {
        expiresLabel =
            '${expiresAt.day} ${_monthLabel(expiresAt.month)} ${expiresAt.year}';

        final diff = expiresAt.difference(DateTime.now()).inDays;
        if (diff > 0) {
          remainingLabel = 'Sisa ± $diff hari';
        } else if (diff == 0) {
          remainingLabel = 'Berakhir hari ini';
        } else {
          remainingLabel = 'Melebihi masa aktif';
        }
      }
    }

    int? totalVoucherTransactions;
    int? currentVoucherUsedCount;

    if (voucherSummary != null) {
      final total = voucherSummary['total_transactions'];
      if (total is int) {
        totalVoucherTransactions = total;
      }

      final currentPackageId =
          (subscription?['wifi_package'] as Map<String, dynamic>?)?['id'];

      final packages = voucherSummary['packages'];
      if (currentPackageId != null && packages is List) {
        for (final item in packages) {
          if (item is Map &&
              item['wifi_package_id'] == currentPackageId &&
              item['count'] is int) {
            currentVoucherUsedCount = item['count'] as int;
            break;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '17.34',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x1F00C8D7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x3300C8D7)),
                            ),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00C8D7), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                  'WiFi · ${_wifiDevicesCount ?? 0} online',
                                  style: const TextStyle(color: Color(0xFF00C8D7), fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '15%',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang,',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?['name'] ?? 'User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'WiFi',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_wifiDevicesCount != null)
                                Text(
                                  '${_wifiDevicesCount} online',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none, color: Colors.white70),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.secondaryColor,
                                child: Text(
                                  (user?['name'] ?? 'U')[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Active Package Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00AAB8),
                          Color(0xFF00CFE0),
                          Color(0xFF00E8CC),
                          Color(0xFF00D4A8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voucher Aktif',
                                style: GoogleFonts.poppins(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                packageName,
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                speedLabel,
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      expiresLabel == '-'
                                          ? 'Masa aktif belum tersedia'
                                          : 'Berlaku hingga $expiresLabel',
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.primaryColor,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              if (remainingLabel != '-')
                                Text(
                                  remainingLabel,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (totalVoucherTransactions != null &&
                                  totalVoucherTransactions > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  (currentVoucherUsedCount ?? 0) > 0
                                      ? 'Voucher ini sudah dipilih ${currentVoucherUsedCount}x'
                                      : 'Belum ada transaksi untuk voucher ini',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                if (totalVoucherTransactions >
                                    (currentVoucherUsedCount ?? 0))
                                  Text(
                                    'Total semua voucher: ${totalVoucherTransactions} transaksi',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121C2C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FEBRIPAY • @${(user?['name'] ?? 'user').toString().split(' ').first.toLowerCase()}',
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Rp ', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                                    Text(
                                      _walletBalance == null ? '-' : _formatRupiah(_walletBalance!).replaceFirst('Rp ', ''),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _showTopUpSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                                ),
                                child: const Text('Top Up', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.14)),
                              ),
                              child: const Text('Kirim', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.14)),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // end FebriPay card inside Column
                  ],
                ),
                // end Column in Stack
              ],
            ),
            ),
            // end header Container

            // Quick Stats Grid
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Penggunaan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Download',
                          value: '45.2',
                          unit: 'GB',
                          color: const Color(0xFF0EA5E9),
                          gradientColors: const [Color(0xFF00C8D7), Color(0xFF00EEFF)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Upload',
                          value: '12.8',
                          unit: 'GB',
                          color: const Color(0xFFF59E0B),
                          gradientColors: const [Color(0xFFD97706), Color(0xFFFBBF24)],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  
                  const SizedBox(height: 32),
                  // WiFi Scanner Compact Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WifiScannerScreen(),
                        ),
                      ).then((_) => _loadWifiCountFromPrefs());
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F6FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.wifi_rounded,
                              color: Color(0xFF00B2CC),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'WiFi\nScanner',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lihat perangkat di jaringanmu',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F4EA),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_wifiCountLoading)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E7D3B)),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: Color(0xFF1E7D3B),
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_wifiDevicesCount ?? 0} online',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E7D3B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Menu Cepat',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildQuickAction(
                        context,
                        Icons.bolt_rounded,
                        'Speed Test',
                        const Color(0xFF4C86F9), // Biru
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SpeedTestScreen(),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        Icons.home_rounded,
                        'Pasang Baru',
                        const Color(0xFF16A34A), // Hijau
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InstallationScreen(),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        Icons.show_chart_rounded,
                        'Status',
                        const Color(0xFF9333EA), // Ungu
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const InstallationStatusScreen(),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        Icons.headphones_rounded,
                        'Bantuan',
                        const Color(0xFFEA580C), // Orange
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupportScreen(),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        Icons.wifi_rounded,
                        'Spot WiFi',
                        const Color(0xFFE11D48), // Pink/Merah
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyWifiScreen(),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        Icons.credit_card_rounded,
                        'Voucher',
                        const Color(0xFF0891B2), // Cyan/Biru Muda
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BillingScreen(),
                          ),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        Icons.chat_bubble_outline_rounded,
                        'Chat',
                        const Color(0xFF7C3AED), // Ungu Terang
                        () {
                          if (_activeSubscription == null) {
                            _showRestrictionDialog('Chat');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 32),
                  if (_recentNotifs.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifikasi Terbaru',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._recentNotifs.take(3).map((n) {
                            final title = n['title']?.toString() ?? 'Notifikasi';
                            final body = n['body']?.toString() ?? '';
                            final type = n['type']?.toString();
                            final deeplink = n['deeplink']?.toString();
                            final data = (n['data'] is Map<String, dynamic>)
                                ? (n['data'] as Map<String, dynamic>)
                                : <String, dynamic>{};
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.notifications_none, color: AppTheme.primaryColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        if (body.isNotEmpty)
                                          Text(
                                            body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      FcmService().openPayloadNavigation(type, data, deeplink);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                    child: Text(
                                      'Buka',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Promo Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F0A24), Color(0xFF1A1040), Color(0xFF0D1A3A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x405B21B6)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PROMO TERBATAS',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Upgrade Speed 2×!',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const Text(
                                'Hanya tambah Rp 50rb/bulan',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0x24FFFFFF)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cek →', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    List<Color>? gradientColors,
  }) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            if (gradientColors != null)
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          unit,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: gradientColors != null
                              ? LinearGradient(colors: gradientColors)
                              : null,
                          color: gradientColors == null ? color : null,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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

  Widget _buildQuickAction(
      BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
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
}
