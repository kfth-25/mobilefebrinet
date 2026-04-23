import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_scan_animation.dart';

class WifiScannerScreen extends StatefulWidget {
  const WifiScannerScreen({super.key});

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _devices = [];
  String? _scanDuration;
  String? _scannedAt;
  String? _serverIp;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/network-scans');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as Map<String, dynamic>;
        final devicesRaw = raw['devices'] as List<dynamic>? ?? [];
        final devices = devicesRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        if (!mounted) return;
        setState(() {
          _devices = devices;
          _scanDuration = raw['scan_duration']?.toString();
          _scannedAt = raw['scanned_at']?.toString();
          _serverIp = raw['server_ip']?.toString();
        });

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('wifi_last_devices_count', devices.length);
          await prefs.setString(
            'wifi_last_scanned_at',
            (_scannedAt?.isNotEmpty == true)
                ? _scannedAt!
                : DateTime.now().toIso8601String(),
          );
        } catch (_) {}
      } else {
        if (!mounted) return;
        if (response.statusCode == 401) {
          setState(() {
            _error =
                'Sesi login berakhir atau tidak valid. Silakan masuk kembali.';
          });
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
        } else if (response.statusCode == 403) {
          String message =
              'Fitur ini hanya tersedia untuk pelanggan dengan langganan aktif.';
          try {
            final body = jsonDecode(response.body);
            if (body is Map && body['message'] != null) {
              message = body['message'].toString();
            }
          } catch (_) {}

          setState(() {
            _error = message;
            _devices = [];
          });
        } else {
          setState(() {
            _error =
                'Gagal memindai jaringan. Kode status: ${response.statusCode}';
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan saat menghubungi server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perangkat Tersambung',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lihat perangkat yang terhubung ke WiFi router Anda.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _scanDevices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(
                    _loading ? 'Memindai...' : 'Scan Ulang',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_scanDuration != null)
                  Text(
                    _scanDuration!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_serverIp != null)
              Text(
                'Server: $_serverIp',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            if (_scannedAt != null)
              Text(
                'Terakhir scan: $_scannedAt',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            Expanded(
              child: _buildDeviceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_loading && _devices.isEmpty) {
      return const Center(
        child: LoadingScanAnimation(
          size: 96,
          label: 'Memindai jaringan...',
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada perangkat terdeteksi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan perangkat aktif dan terhubung\nke WiFi router Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final devices = List<Map<String, dynamic>>.from(_devices);
    final routers =
        devices.where((d) => d['is_gateway'] == true).toList();
    final others =
        devices.where((d) => d['is_gateway'] != true).toList();

    others.sort((a, b) {
      final ipA = a['ip_address']?.toString() ?? '';
      final ipB = b['ip_address']?.toString() ?? '';
      return ipA.compareTo(ipB);
    });

    final orderedDevices = [...routers, ...others];

    return ListView.separated(
      itemCount: orderedDevices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = orderedDevices[index];
        final ip = device['ip_address']?.toString() ?? '-';
        final mac = device['mac_address']?.toString() ?? '-';
        final vendor = device['vendor']?.toString();
        final hostname = device['hostname']?.toString();
        final isGateway = device['is_gateway'] == true;
        final icon = _iconForDevice(device);
        final color = isGateway
            ? AppTheme.primaryColor
            : Colors.grey[700] ?? Colors.grey;
        final label = _labelForDevice(device);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGateway
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleForDevice(
                              ip: ip,
                              hostname: hostname,
                              isGateway: isGateway,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        if (isGateway)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Router',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (hostname != null && hostname.isNotEmpty)
                      Text(
                        'Hostname: $hostname',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    if (vendor != null && vendor.isNotEmpty)
                      Text(
                        vendor,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    Text(
                      mac,
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
        );
      },
    );
  }

  IconData _iconForDevice(Map<String, dynamic> device) {
    final isGateway = device['is_gateway'] == true;
    if (isGateway) {
      return Icons.router;
    }
    final vendorRaw = device['vendor'];
    final vendor = vendorRaw?.toString().toLowerCase() ?? '';

    if (vendor.contains('apple') || vendor.contains('iphone')) {
      return Icons.phone_iphone;
    }
    if (vendor.contains('samsung') ||
        vendor.contains('xiaomi') ||
        vendor.contains('oppo') ||
        vendor.contains('vivo') ||
        vendor.contains('realme') ||
        vendor.contains('huawei')) {
      return Icons.smartphone;
    }
    if (vendor.contains('asus') ||
        vendor.contains('acer') ||
        vendor.contains('lenovo') ||
        vendor.contains('dell') ||
        vendor.contains('hp') ||
        vendor.contains('msi')) {
      return Icons.laptop;
    }

    return Icons.devices_other;
  }

  String _titleForDevice({
    required String ip,
    required String? hostname,
    required bool isGateway,
  }) {
    final hasHostname = hostname != null && hostname.isNotEmpty;
    if (isGateway) {
      if (hasHostname) {
        return '$hostname ($ip)';
      }
      return 'Router WiFi ($ip)';
    }

    if (hasHostname) {
      return hostname;
    }

    return ip;
  }

  String _labelForDevice(Map<String, dynamic> device) {
    final isGateway = device['is_gateway'] == true;
    if (isGateway) {
      return 'Perangkat ini adalah router utama jaringan Anda.';
    }

    final vendorRaw = device['vendor'];
    final vendor = vendorRaw?.toString().toLowerCase() ?? '';

    if (vendor.contains('apple') || vendor.contains('iphone')) {
      return 'Kemungkinan ponsel atau perangkat Apple.';
    }
    if (vendor.contains('samsung') ||
        vendor.contains('xiaomi') ||
        vendor.contains('oppo') ||
        vendor.contains('vivo') ||
        vendor.contains('realme') ||
        vendor.contains('huawei')) {
      return 'Kemungkinan ponsel Android.';
    }
    if (vendor.contains('asus') ||
        vendor.contains('acer') ||
        vendor.contains('lenovo') ||
        vendor.contains('dell') ||
        vendor.contains('hp') ||
        vendor.contains('msi')) {
      return 'Kemungkinan laptop atau komputer.';
    }

    return 'Jenis perangkat tidak diketahui.';
  }
}
