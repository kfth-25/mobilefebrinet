import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String title;
  final String body;
  final String? type;
  final String? deeplink;
  final String ts;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    this.type,
    this.deeplink,
    required this.ts,
    this.isRead = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    return AppNotification(
      title: m['title']?.toString() ?? 'Notifikasi',
      body: m['body']?.toString() ?? '',
      type: m['type']?.toString(),
      deeplink: m['deeplink']?.toString(),
      ts: m['ts']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: m['isRead'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'type': type,
        'deeplink': deeplink,
        'ts': ts,
        'isRead': isRead,
      };
}

/// Global callback – set this from FcmService to trigger in-app banner
typedef InAppBannerCallback = void Function(AppNotification notif);

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  AppNotification? _incomingBanner; // notif to show as in-app banner

  // External handler: UI listens to this via addBannerListener
  InAppBannerCallback? _bannerCallback;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  AppNotification? get incomingBanner => _incomingBanner;

  void addBannerListener(InAppBannerCallback cb) => _bannerCallback = cb;
  void removeBannerListener() => _bannerCallback = null;

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('recent_notifications');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _notifications = decoded
              .whereType<Map>()
              .map((e) => AppNotification.fromMap(
                    e.map((k, v) => MapEntry(k.toString(), v)),
                  ))
              .toList();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'recent_notifications',
          jsonEncode(_notifications.map((n) => n.toMap()).toList()));
    } catch (_) {}
  }

  /// Called by FcmService when a new foreground notification arrives
  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    if (_notifications.length > 30) _notifications = _notifications.sublist(0, 30);
    notifyListeners();
    _saveToPrefs();
    // trigger banner
    _bannerCallback?.call(notif);
  }

  void markRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index].isRead = true;
      notifyListeners();
      _saveToPrefs();
    }
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    _saveToPrefs();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
    _saveToPrefs();
  }

  /// Called from FcmService to emit in-app banner
  void triggerBanner(AppNotification notif) {
    _bannerCallback?.call(notif);
  }
}
