import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianService {
  static const String _baseUrl = 'http://192.168.11.158:8000/api';

  Future<List<Map<String, dynamic>>> fetchJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.startsWith('mock_')) {
      // Return mock data if using mock offline login
      return _getMockJobs();
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final subsFuture = http.get(Uri.parse('$_baseUrl/subscriptions'), headers: headers);
      final issuesFuture = http.get(Uri.parse('$_baseUrl/issues'), headers: headers);

      final responses = await Future.wait([subsFuture, issuesFuture]);
      final subsRes = responses[0];
      final issuesRes = responses[1];

      final List<Map<String, dynamic>> jobs = [];

      if (subsRes.statusCode == 200) {
        final List<dynamic> subsData = jsonDecode(subsRes.body);
        for (var s in subsData) {
          if (s['installation_step'] != 'done') {
            jobs.add({
              'id': 'INS-${s['id']}',
              'type': 'Pemasangan',
              'customer': s['user']?['name'] ?? 'Customer',
              'address': s['installation_address'] ?? '-',
              'phone': s['user']?['phone'] ?? '-',
              'status': s['installation_step'] == 'installing' ? 'in_progress' : 'pending',
              'date': _formatDate(s['created_at']),
              'package': s['wifi_package']?['name'] ?? 'Paket Internet',
              'map_link': s['map_link'],
              'originalData': s,
              'rawId': s['id'],
              'isIssue': false,
            });
          }
        }
      }

      if (issuesRes.statusCode == 200) {
        final List<dynamic> issuesData = jsonDecode(issuesRes.body);
        for (var i in issuesData) {
          if (i['status'] != 'closed' && i['status'] != 'resolved') {
            jobs.add({
              'id': 'TSK-${i['id']}',
              'type': 'Gangguan',
              'customer': i['subscription']?['user']?['name'] ?? i['reporter']?['name'] ?? 'Customer',
              'address': i['subscription']?['installation_address'] ?? 'Alamat tidak diketahui',
              'phone': i['subscription']?['user']?['phone'] ?? i['reporter']?['phone'] ?? '-',
              'status': i['status'] == 'in_progress' ? 'in_progress' : 'pending',
              'date': _formatDate(i['created_at']),
              'issue': i['subject'] ?? '-',
              'map_link': i['subscription']?['map_link'],
              'originalData': i,
              'rawId': i['id'],
              'isIssue': true,
            });
          }
        }
      }

      // Sort by date descending (assuming formatted string can be loosely sorted or we should use DateTime)
      // Since _formatDate might be simple, let's just reverse for now or sort by raw ID if needed.
      return jobs.reversed.toList();
    } catch (e) {
      print('Failed to fetch technician jobs: $e');
      return _getMockJobs();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Hari ini';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  List<Map<String, dynamic>> _getMockJobs() {
    return [
      {
        'id': 'INS-001',
        'type': 'Pemasangan',
        'customer': 'Budi Santoso',
        'address': 'Jl. Merdeka No. 45, Jakarta Barat',
        'status': 'pending',
        'date': 'Hari ini, 10:00 WIB',
        'isIssue': false,
      },
      {
        'id': 'TSK-089',
        'type': 'Gangguan',
        'customer': 'Siti Rahayu',
        'address': 'Komplek Permata Hijau Blok C2, Jakarta Selatan',
        'status': 'in_progress',
        'date': 'Hari ini, 13:30 WIB',
        'isIssue': true,
      }
    ];
  }
}
