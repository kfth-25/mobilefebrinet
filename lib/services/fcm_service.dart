import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_service.dart';
import '../screens/main_screen.dart';
import '../screens/installation/installation_status_screen.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final notification = message.notification;
  if (notification != null) {
    await NotificationService().show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: notification.title ?? 'Notifikasi',
      body: notification.body ?? '',
      payload: jsonEncode(message.data),
    );
  }
}

class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  NotificationProvider? _notifProvider;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        if (notification != null) {
          await NotificationService().show(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: notification.title ?? 'Notifikasi',
            body: notification.body ?? '',
            payload: jsonEncode(message.data),
          );
          final appNotif = AppNotification(
            title: notification.title ?? 'Notifikasi',
            body: notification.body ?? '',
            type: message.data['type']?.toString(),
            deeplink: message.data['deeplink']?.toString(),
            ts: DateTime.now().toIso8601String(),
          );
          _notifProvider?.addNotification(appNotif);
          // Also save to prefs for persistence
          await _saveRecentNotification(
            title: notification.title ?? 'Notifikasi',
            body: notification.body ?? '',
            type: message.data['type']?.toString(),
            deeplink: message.data['deeplink']?.toString(),
            data: message.data,
          );
        }
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
        await _postRegisterToken(token);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleOpenedMessage(message);
      });
      _initialized = true;
    } catch (_) {
      // ignore init errors (e.g., missing google-services.json), fallback to local only
      _initialized = true;
    }
  }

  static void registerBackgroundHandler() {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
  }

  Future<String?> getTokenOrNull() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAndRegisterToken() async {
    final t = await getTokenOrNull();
    if (t != null) {
      await _postRegisterToken(t);
    }
  }

  Future<void> _postRegisterToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bearer = prefs.getString('token');
      if (bearer == null) return;
      await http.post(
        Uri.parse('${AuthProvider.baseUrl}/devices/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $bearer',
        },
        body: jsonEncode({
          'token': token,
          'platform': 'android',
        }),
      );
    } catch (_) {}
  }

  void attachNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void attachNotificationProvider(NotificationProvider provider) {
    _notifProvider = provider;
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString();
    final deeplink = data['deeplink']?.toString();
    _navigate(type, data, deeplink);
  }

  Future<void> _saveRecentNotification({
    required String title,
    required String body,
    String? type,
    String? deeplink,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('recent_notifications');
      List<Map<String, dynamic>> list = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list = decoded
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        }
      }
      list.insert(0, {
        'title': title,
        'body': body,
        'type': type,
        'deeplink': deeplink,
        'data': data ?? {},
        'ts': DateTime.now().toIso8601String(),
      });
      if (list.length > 10) {
        list = list.sublist(0, 10);
      }
      await prefs.setString('recent_notifications', jsonEncode(list));
    } catch (_) {}
  }

  void _navigate(String? type, Map<String, dynamic> data, String? deeplink) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    int? issueId;
    int? subscriptionId;
    if (deeplink != null && deeplink.isNotEmpty) {
      try {
        final uri = Uri.parse(deeplink);
        issueId = int.tryParse(uri.queryParameters['issue_id'] ?? '');
        subscriptionId = int.tryParse(uri.queryParameters['id'] ?? '');
        if (uri.host == 'billing') {
          nav.push(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)));
          return;
        }
        if (uri.host == 'support' && uri.path.startsWith('/outage')) {
          nav.push(MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 3, initialIssueId: issueId)));
          return;
        }
        if (uri.host == 'installation' && uri.path.startsWith('/status')) {
          nav.push(MaterialPageRoute(builder: (_) => InstallationStatusScreen(initialSubscriptionId: subscriptionId)));
          return;
        }
      } catch (_) {}
    }
    switch (type) {
      case 'billing_due':
      case 'payment_received':
        nav.push(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)));
        break;
      case 'outage':
        nav.push(MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 3, initialIssueId: (data['issue_id'] is int) ? (data['issue_id'] as int) : int.tryParse('${data['issue_id'] ?? ''}'))));
        break;
      case 'request_update':
        nav.push(MaterialPageRoute(builder: (_) => InstallationStatusScreen(initialSubscriptionId: (data['subscription_id'] is int) ? (data['subscription_id'] as int) : int.tryParse('${data['subscription_id'] ?? ''}'))));
        break;
      default:
        break;
    }
  }

  void openPayloadNavigation(String? type, Map<String, dynamic> data, String? deeplink) {
    _navigate(type, data, deeplink);
  }
}
