 import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_scan_animation.dart'; // Ensure this exists or mock it

class NearbyWifiScreen extends StatefulWidget {
  const NearbyWifiScreen({super.key});

  @override
  State<NearbyWifiScreen> createState() => _NearbyWifiScreenState();
}

class _NearbyWifiScreenState extends State<NearbyWifiScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _devices = [];
  String? _scanDuration;
  String? _scannedAt;
  
  // Animation controller for the radar scan
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    // Start scan automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanDevices();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
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

      // Simulate a minimum delay for the animation to be seen
      final startTime = DateTime.now();
      
      final response = await http.post(uri, headers: headers);
      
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 1500) {
        await Future.delayed(Duration(milliseconds: 1500 - elapsed.inMilliseconds));
      }

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
        });

        // Save count to prefs
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('wifi_last_devices_count', devices.length);
        } catch (_) {}
      } else {
        if (!mounted) return;
        // Error handling
        String message = 'Gagal memindai jaringan.';
        if (response.statusCode == 403) {
           final body = jsonDecode(response.body);
           if (body is Map && body['message'] != null) {
             message = body['message'].toString();
           } else {
             message = 'Akses ditolak. Langganan aktif diperlukan.';
           }
        }
        setState(() {
          _error = message;
          // Fallback empty list
          _devices = []; 
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan koneksi.';
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
    // Count stats
    final total = _devices.length;
    // Mock logic for "Online", "Offline", "Asing" since backend might not provide it yet
    // Assuming all scanned are "Online" now.
    // We can randomize or check 'last_seen' if available.
    final onlineCount = total > 0 ? total : 0;
    final offlineCount = 0; // Placeholder
    final foreignCount = _devices.where((d) => _isForeign(d)).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1221), // Dark background for status bar
      body: Column(
        children: [
          // 1. Header Section (Dark)
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF080F20), Color(0xFF0F1E3D), Color(0xFF1A0A1C)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Back Button & Title & Scan Button
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.09)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JARINGAN LOKAL',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white38,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Spot WiFi',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Scan Ulang Button
                    InkWell(
                      onTap: _loading ? null : _scanDevices,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            if (_loading)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE11D48)),
                              )
                            else
                              const Icon(Icons.wifi_tethering, color: Color(0xFFE11D48), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Scan Ulang',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Big Counter
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$total',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'perangkat',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Chips
                Row(
                  children: [
                    _buildStatusChip('Online', onlineCount, const Color(0xFF059669), const Color(0xFF34D399)),
                    const SizedBox(width: 8),
                    _buildStatusChip('Offline', offlineCount, const Color(0xFF4B5563), Colors.white38),
                    const SizedBox(width: 8),
                    _buildStatusChip('Asing', foreignCount, const Color(0xFFD97706), const Color(0xFFFBBF24)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Content Body (White rounded)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F4F9),
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
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Radar/Map Visualization
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A1525), Color(0xFF162D56)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF00C8D7).withOpacity(0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Grid Background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridPainter(color: const Color(0xFF00C8D7).withOpacity(0.05)),
                            ),
                          ),
                          // Radar Animation (Only if loading)
                          if (_loading)
                            Center(
                              child: AnimatedBuilder(
                                animation: _radarController,
                                builder: (context, child) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE11D48).withOpacity(1.0 - _radarController.value),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 100 * _radarController.value,
                                        height: 100 * _radarController.value,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFE11D48).withOpacity(0.1 * (1.0 - _radarController.value)),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Dots (Simulated devices)
                          if (!_loading && _devices.isNotEmpty)
                             ...List.generate(math.min(_devices.length, 5), (index) {
                               final r = math.Random(index);
                               return Positioned(
                                 top: 30 + r.nextDouble() * 80,
                                 left: 30 + r.nextDouble() * 200,
                                 child: Container(
                                   width: 12,
                                   height: 12,
                                   decoration: BoxDecoration(
                                     color: index == 0 ? const Color(0xFF00C8D7) : (_isForeign(_devices[index]) ? const Color(0xFFFBBF24) : Colors.white),
                                     shape: BoxShape.circle,
                                     boxShadow: [
                                       BoxShadow(
                                         color: (index == 0 ? const Color(0xFF00C8D7) : Colors.white).withOpacity(0.5),
                                         blurRadius: 8,
                                         spreadRadius: 2,
                                       )
                                     ],
                                   ),
                                 ).animate(onPlay: (c) => c.repeat(reverse: true))
                                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: Duration(milliseconds: 1000 + index * 200)),
                               );
                             }),
                          
                          // Network Name Label
                          Positioned(
                            bottom: 16,
                            left: 20,
                            child: Row(
                              children: [
                                Text(
                                  'Jaringan: ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Febri.net-Home', // Placeholder or fetch SSID if possible
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF00C8D7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (_loading)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 40),
                                  Text(
                                    'Sedang memindai...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Perangkat Terdeteksi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A0F1E),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_loading && _devices.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      )),

                    if (!_loading && _devices.isEmpty && _error == null)
                       Center(
                         child: Padding(
                           padding: const EdgeInsets.all(20.0),
                           child: Text(
                             'Tidak ada perangkat ditemukan',
                             style: GoogleFonts.poppins(color: Colors.grey),
                           ),
                         ),
                       ),
                    
                    if (_error != null)
                      Center(
                         child: Padding(
                           padding: const EdgeInsets.all(20.0),
                           child: Text(
                             _error!,
                             style: GoogleFonts.poppins(color: Colors.red),
                             textAlign: TextAlign.center,
                           ),
                         ),
                       ),

                    // Device List
                    ..._devices.map((device) => _buildDeviceCard(device)).toList(),
                    
                    const SizedBox(height: 24),
                    
                    // Foreign Device Warning Card (if any)
                    if (foreignCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED), // Orange/Warning light
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDBA74)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEDD5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perangkat tidak dikenal!',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: const Color(0xFF9A3412),
                                    ),
                                  ),
                                  Text(
                                    'MAC tidak terdaftar. Pertimbangkan untuk memblokir.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFFC2410C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Block logic placeholder
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur blokir akan segera tersedia')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Blokir Perangkat Asing',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final ip = device['ip_address']?.toString() ?? '-';
    final mac = device['mac_address']?.toString() ?? '-';
    final vendor = device['vendor']?.toString() ?? 'Unknown';
    final hostname = device['hostname']?.toString();
    
    // Determine type
    final isGateway = device['is_gateway'] == true;
    final isForeign = _isForeign(device);
    // Mock "My Device" logic - usually would check IP against local IP
    // For now, let's assume if it's not gateway and not foreign, it might be "Kamu" 
    // strictly for visual demo if we can't determine it. 
    // Actually, let's just use a flag if we had one. I'll omit "Kamu" badge if unsure.
    final isMe = false; // Placeholder

    final iconData = _getIcon(vendor, isGateway);
    
    // Styling based on status
    final cardColor = isForeign ? const Color(0xFFFFFBEB) : Colors.white;
    final borderColor = isForeign ? const Color(0xFFFCD34D) : const Color(0xFFE4E9F4);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isGateway 
                  ? AppTheme.primaryColor.withOpacity(0.1) 
                  : (isForeign ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconData,
              color: isGateway 
                  ? AppTheme.primaryColor 
                  : (isForeign ? Colors.orange : Colors.blue),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        hostname ?? vendor,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0F1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                       Container(
                         margin: const EdgeInsets.only(left: 6),
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                           color: const Color(0xFF00C8D7).withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: const Color(0xFF00C8D7).withOpacity(0.2)),
                         ),
                         child: Text(
                           'Kamu',
                           style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF00C8D7)),
                         ),
                       ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mac.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Right Side (IP & Signal)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Signal bars (Mock)
              Row(
                children: [
                  _buildSignalBar(true),
                  const SizedBox(width: 2),
                  _buildSignalBar(true),
                  const SizedBox(width: 2),
                  _buildSignalBar(true),
                  const SizedBox(width: 2),
                  _buildSignalBar(false),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ip,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBar(bool active) {
    return Container(
      width: 3,
      height: 10, // varying heights could be cool but fixed for simplicity
      decoration: BoxDecoration(
        color: active ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  bool _isForeign(Map<String, dynamic> device) {
    // Simple mock logic: If vendor is unknown or empty, mark as foreign for demo
    // Or if specifically flagged (which isn't in current API, but we can simulate)
    final vendor = device['vendor']?.toString().toLowerCase() ?? '';
    return vendor.isEmpty || vendor == 'unknown';
  }

  IconData _getIcon(String vendorRaw, bool isGateway) {
    if (isGateway) return Icons.router;
    final vendor = vendorRaw.toLowerCase();
    if (vendor.contains('apple') || vendor.contains('iphone') || vendor.contains('ipad')) return Icons.phone_iphone;
    if (vendor.contains('macbook') || vendor.contains('imac')) return Icons.laptop_mac;
    if (vendor.contains('android') || vendor.contains('samsung') || vendor.contains('xiaomi')) return Icons.smartphone;
    if (vendor.contains('tv')) return Icons.tv;
    return Icons.devices;
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
