import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool _billing = true;
  bool _outage = true;
  bool _request = true;
  bool _emailEnabled = true;
  String _quietHours = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPreferences();
    });
  }

  Future<void> _fetchPreferences() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/notification-preferences');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _billing = (raw['billing'] ?? true) == true;
          _outage = (raw['outage'] ?? true) == true;
          _request = (raw['request'] ?? true) == true;
          _emailEnabled = (raw['email_enabled'] ?? true) == true;
          _quietHours = raw['quiet_hours']?.toString() ?? '';
        });
      } else {
        setState(() {
          _error = 'Gagal memuat preferensi notifikasi.';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Gagal memuat preferensi notifikasi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _updatePref(Map<String, dynamic> patch) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/notification-preferences');
      final resp = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(patch),
      );
      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _billing = (raw['billing'] ?? _billing) == true;
          _outage = (raw['outage'] ?? _outage) == true;
          _request = (raw['request'] ?? _request) == true;
          _emailEnabled = (raw['email_enabled'] ?? _emailEnabled) == true;
          _quietHours = raw['quiet_hours']?.toString() ?? _quietHours;
        });
      } else {
        setState(() {
          _error = 'Gagal menyimpan preferensi.';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Gagal menyimpan preferensi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickQuietHours() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor)), child: child!);
      },
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor)), child: child!);
      },
    );
    if (end == null) return;

    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    final value = '$startStr-$endStr';
    setState(() {
      _quietHours = value;
    });
    await _updatePref({'quiet_hours': value});
  }

  Future<void> _clearQuietHours() async {
    setState(() {
      _quietHours = '';
    });
    await _updatePref({'quiet_hours': ''});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan Notifikasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Kategori'),
                    _buildSwitchCard(
                      title: 'Tagihan',
                      subtitle: 'Pengingat jatuh tempo dan konfirmasi pembayaran.',
                      value: _billing,
                      onChanged: (v) {
                        setState(() => _billing = v);
                        _updatePref({'billing': v});
                      },
                    ),
                    _buildSwitchCard(
                      title: 'Gangguan Jaringan',
                      subtitle: 'Info gangguan dan pemulihan layanan.',
                      value: _outage,
                      onChanged: (v) {
                        setState(() => _outage = v);
                        _updatePref({'outage': v});
                      },
                    ),
                    _buildSwitchCard(
                      title: 'Status Permohonan',
                      subtitle: 'Perubahan status pemasangan/langganan.',
                      value: _request,
                      onChanged: (v) {
                        setState(() => _request = v);
                        _updatePref({'request': v});
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Email'),
                    _buildSwitchCard(
                      title: 'Kirim Email',
                      subtitle: 'Terima notifikasi via email selain push.',
                      value: _emailEnabled,
                      onChanged: (v) {
                        setState(() => _emailEnabled = v);
                        _updatePref({'email_enabled': v});
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Quiet Hours'),
                    _buildQuietHoursCard(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (_saving)
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Menyimpan...',
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rentang Waktu',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _quietHours.isNotEmpty ? _quietHours : 'Tidak diatur',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickQuietHours,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(
                    'Atur',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tidak akan mengirim notifikasi non‑kritis pada jam yang diatur.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (_quietHours.isNotEmpty)
                  TextButton(
                    onPressed: _clearQuietHours,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(
                      'Hapus',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

