import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/in_app_notif_banner.dart';
import 'billing/billing_screen.dart';
import 'home/aktivitas_screen.dart';
import 'home/dashboard_screen.dart';
import 'community/komunitas_screen.dart';
import 'profile/profile_screen.dart';
import 'support/support_screen.dart';
import 'technician/technician_dashboard_screen.dart';
import 'technician/technician_tasks_screen.dart';
import 'notification/notification_screen.dart'; // still used by banner overlay tap

class MainScreen extends StatefulWidget {
  final int? initialIndex;
  final int? initialIssueId;
  const MainScreen({super.key, this.initialIndex, this.initialIssueId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 1;
  late final PageController _pageController;
  final GlobalKey<_NotifBannerOverlayState> _overlayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    if (widget.initialIndex != null) {
      final old = widget.initialIndex!;
      if (old == 0) _pageIndex = 1;
      if (old == 2) _pageIndex = 0;
      if (old == 4) _pageIndex = 3;
      if (old == 3) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SupportScreen(initialIssueId: widget.initialIssueId),
            ),
          );
        });
      }
      _pageController.jumpToPage(_pageIndex);
    }

    // Register banner trigger with NotificationProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.loadFromPrefs();
      provider.addBannerListener((notif) {
        _overlayKey.currentState?.show(notif);
      });
    });
  }

  @override
  void dispose() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.removeBannerListener();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isTechnician = auth.user?['role'] == 'technician';

    final screens = isTechnician
        ? const [
            TechnicianDashboardScreen(),
            TechnicianTasksScreen(),
            KomunitasScreen(),
            ProfileScreen(),
          ]
        : const [
            AktivitasScreen(),
            DashboardScreen(),
            KomunitasScreen(),
            ProfileScreen(),
          ];

    return _NotifBannerOverlay(
      overlayKey: _overlayKey,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _pageIndex = i),
          children: screens,
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF202734),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    icon: isTechnician ? Icons.home_repair_service : Icons.timeline_rounded,
                    label: isTechnician ? 'Beranda' : 'Aktivitas',
                    selected: _pageIndex == 0,
                    onTap: () {
                      setState(() => _pageIndex = 0);
                      _pageController.animateToPage(0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    },
                  ),
                  _NavItem(
                    icon: isTechnician ? Icons.assignment : Icons.home,
                    label: isTechnician ? 'Tugas' : 'Home',
                    selected: _pageIndex == 1,
                    onTap: () {
                      setState(() => _pageIndex = 1);
                      _pageController.animateToPage(1,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    },
                  ),
                  _NavItem(
                    icon: Icons.groups_rounded,
                    label: 'Komunitas',
                    selected: _pageIndex == 2,
                    onTap: () {
                      setState(() => _pageIndex = 2);
                      _pageController.animateToPage(2,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    },
                  ),
                  _NavItem(
                    icon: Icons.person,
                    label: 'Akun',
                    selected: _pageIndex == 3,
                    onTap: () {
                      setState(() => _pageIndex = 3);
                      _pageController.animateToPage(3,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Notif Banner Overlay ────────────────────────────────────────────────────

class _NotifBannerOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<_NotifBannerOverlayState> overlayKey;

  const _NotifBannerOverlay({
    required this.child,
    required this.overlayKey,
  }) : super(key: overlayKey);

  @override
  _NotifBannerOverlayState createState() => _NotifBannerOverlayState();
}

class _NotifBannerOverlayState extends State<_NotifBannerOverlay> {
  AppNotification? _current;

  void show(AppNotification notif) {
    setState(() => _current = notif);
  }

  void _dismiss() => setState(() => _current = null);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InAppNotifBanner(
                notification: _current!,
                onTap: () {
                  _dismiss();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
                onDismiss: _dismiss,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Nav Items ───────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1E5264) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: Colors.white.withOpacity(selected ? 1 : 0.75)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color:
                      Colors.white.withOpacity(selected ? 1 : 0.85),
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 2,
                  width: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25E3FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// _NotifNavItem removed — notification accessed via bell icon in home header
