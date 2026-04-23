import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fcm_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  static const String _baseUrl = 'http://192.168.11.158:8000/api';

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  static String get baseUrl => _baseUrl;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (_token != null && userJson != null) {
      _isAuthenticated = true;
      _user = jsonDecode(userJson) as Map<String, dynamic>;

      try {
        final dynamic uid = _user!['id'];
        if (uid != null) {
          SocketService().connect('user-$uid');
        } else if (_token == 'mock_token_offline') {
          SocketService().connect('user-mock');
        }
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (accessToken != null && userData != null) {
          _isAuthenticated = true;
          _token = accessToken;
          _user = userData;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', accessToken);
          await prefs.setString('user', jsonEncode(userData));

          try {
            await FcmService().init();
            final t = await FcmService().getTokenOrNull();
            if (t != null) {
              await _registerDeviceToken(t, platform: 'android');
            }
          } catch (_) {
            try {
              await _registerDeviceToken('local-only', platform: 'android');
            } catch (_) {}
          }

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      // You can add logging here if needed
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        final dynamic userRaw = data['user'];
        final Map<String, dynamic>? userData =
            userRaw is Map<String, dynamic> ? userRaw : null;
        if (accessToken != null && userData != null) {
          _isAuthenticated = true;
          _token = accessToken;
          _user = userData;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', accessToken);
          await prefs.setString('user', jsonEncode(userData));

          try {
            final dynamic uid = userData['id'];
            if (uid != null) {
              SocketService().connect('user-$uid');
            }
          } catch (_) {}

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
    }

    if (email == 'user@febri.net' && password == 'user123') {
      final mockUser = <String, dynamic>{
        'name': 'Febri User',
        'email': 'user@febri.net',
        'role': 'customer',
      };

      _isAuthenticated = true;
      _token = 'mock_token_offline';
      _user = mockUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(mockUser));

      try {
        await FcmService().init();
        final t = await FcmService().getTokenOrNull();
        if (t != null) {
          await _registerDeviceToken(t, platform: 'android');
        } else {
          await _registerDeviceToken('local-only', platform: 'android');
        }
      } catch (_) {
        try {
          await _registerDeviceToken('local-only', platform: 'android');
        } catch (_) {}
      }

      try {
        SocketService().connect('user-mock');
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } else if (email == 'tech@febri.net' && password == 'tech123') {
      final mockUser = <String, dynamic>{
        'name': 'Febri Tech',
        'email': 'tech@febri.net',
        'role': 'technician',
      };

      _isAuthenticated = true;
      _token = 'mock_token_tech_offline';
      _user = mockUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(mockUser));

      try {
        await FcmService().init();
        final t = await FcmService().getTokenOrNull();
        if (t != null) {
          await _registerDeviceToken(t, platform: 'android');
        } else {
          await _registerDeviceToken('local-only', platform: 'android');
        }
      } catch (_) {
        try {
          await _registerDeviceToken('local-only', platform: 'android');
        } catch (_) {}
      }

      try {
        SocketService().connect('user-mock');
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _registerDeviceToken(String token, {String? platform}) async {
    if (_token == null) return;
    await http.post(
      Uri.parse('$_baseUrl/devices/register-token'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'token': token,
        if (platform != null) 'platform': platform,
      }),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (_) {
      // ignore network errors on logout
    } finally {
      _isAuthenticated = false;
      _token = null;
      _user = null;

      await prefs.remove('token');
      await prefs.remove('user');

      try {
        SocketService().disconnect(_user?['id'] != null ? 'user-${_user!['id']}' : 'user-mock');
      } catch (_) {}

      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    if (_token == null || _user == null) return false;
    final dynamic idRaw = _user!['id'];
    if (idRaw == null) return false;

    final int? userId =
        idRaw is int ? idRaw : int.tryParse(idRaw.toString());
    if (userId == null) return false;

    final Map<String, dynamic> payload = {};
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;
    if (payload.isEmpty) return false;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>;
        _user = data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));

        notifyListeners();
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_token == null || _user == null) {
      return 'Anda belum masuk.';
    }

    final dynamic idRaw = _user!['id'];
    if (idRaw == null) return 'Data akun tidak lengkap.';

    final int? userId =
        idRaw is int ? idRaw : int.tryParse(idRaw.toString());
    if (userId == null) return 'Data akun tidak valid.';

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        return null;
      }

      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          return body['message'].toString();
        }
      } catch (_) {}

      return 'Gagal mengubah password.';
    } catch (_) {
      return 'Gagal mengubah password.';
    }
  }
}
