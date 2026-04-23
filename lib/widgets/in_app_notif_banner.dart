import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';

/// A slide-down banner that appears at the top of the screen
/// when a foreground notification arrives.
class InAppNotifBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const InAppNotifBanner({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<InAppNotifBanner> createState() => _InAppNotifBannerState();
}

class _InAppNotifBannerState extends State<InAppNotifBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    // auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _iconColor(String? type) {
    switch (type) {
      case 'billing_due': return const Color(0xFFE11D48);
      case 'payment_received': return const Color(0xFF059669);
      case 'outage': return const Color(0xFFD97706);
      default: return const Color(0xFF00C8D7);
    }
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'billing_due': return Icons.receipt_long;
      case 'payment_received': return Icons.check_circle;
      case 'outage': return Icons.wifi_off;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _iconColor(widget.notification.type);
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: () {
            _dismiss();
            widget.onTap();
          },
          onVerticalDragStart: (_) => _dismiss(),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 52, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F36),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(widget.notification.type),
                      color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.notification.title,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.notification.body,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close, size: 16, color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the entire app (or a page) to show in-app banners
class NotifBannerOverlay extends StatefulWidget {
  final Widget child;
  const NotifBannerOverlay({super.key, required this.child});

  @override
  State<NotifBannerOverlay> createState() => _NotifBannerOverlayState();

  static _NotifBannerOverlayState? of(BuildContext ctx) =>
      ctx.findAncestorStateOfType<_NotifBannerOverlayState>();
}

class _NotifBannerOverlayState extends State<NotifBannerOverlay> {
  final List<AppNotification> _queue = [];
  bool _showing = false;

  void show(AppNotification notif) {
    setState(() => _queue.add(notif));
    if (!_showing) _processQueue();
  }

  void _processQueue() {
    if (_queue.isEmpty) {
      setState(() => _showing = false);
      return;
    }
    setState(() => _showing = true);
  }

  void _onDismiss() {
    if (_queue.isNotEmpty) _queue.removeAt(0);
    _processQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showing && _queue.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InAppNotifBanner(
                notification: _queue.first,
                onTap: _onDismiss,
                onDismiss: _onDismiss,
              ),
            ),
          ),
      ],
    );
  }
}
