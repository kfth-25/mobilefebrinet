import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedFilter = 'Semua';

  // Sesuai dengan mockup admin: Umum, Tagihan, Pembayaran, Gangguan, Instalasi, Promo
  final List<String> _filters = [
    'Semua',
    'Umum',
    'Tagihan',
    'Pembayaran',
    'Gangguan',
    'Instalasi',
    'Promo'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final filteredNotifs = _getFilteredNotifications(provider.notifications);
        
        // Count unread for specific tabs based on mockup
        int unreadUmum = provider.notifications.where((n) => !n.isRead && (n.type == 'general' || n.type == 'umum')).length;
        int unreadTagihan = provider.notifications.where((n) => !n.isRead && (n.type == 'billing_due' || n.type == 'tagihan')).length;
        int unreadPembayaran = provider.notifications.where((n) => !n.isRead && (n.type == 'payment_received' || n.type == 'pembayaran')).length;
        int unreadGangguan = provider.notifications.where((n) => !n.isRead && (n.type == 'outage' || n.type == 'gangguan')).length;
        int unreadInstalasi = provider.notifications.where((n) => !n.isRead && (n.type == 'request_update' || n.type == 'instalasi')).length;
        int unreadPromo = provider.notifications.where((n) => !n.isRead && (n.type == 'promo' || n.type == 'voucher')).length;

        Map<String, int> tabCounts = {
          'Semua': provider.unreadCount,
          'Umum': unreadUmum,
          'Tagihan': unreadTagihan,
          'Pembayaran': unreadPembayaran,
          'Gangguan': unreadGangguan,
          'Instalasi': unreadInstalasi,
          'Promo': unreadPromo,
        };

        return Scaffold(
          backgroundColor: const Color(0xFF0B1221), // MATCH BILLING SCREEN HEADER
          body: Column(
            children: [
              _buildModernAppBar(provider, tabCounts),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA), // Light background for content
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
                    child: filteredNotifs.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 20, bottom: 30),
                            itemCount: filteredNotifs.length,
                            itemBuilder: (context, index) {
                              final notif = filteredNotifs[index];
                              final actualIndex = provider.notifications.indexOf(notif);
                              
                              // Check if this is the first item of a date to show date header
                              bool showDate = true;
                              if (index > 0) {
                                String prevDate = _getDateString(filteredNotifs[index - 1].ts);
                                String currDate = _getDateString(notif.ts);
                                if (prevDate == currDate) showDate = false;
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showDate)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
                                      child: Text(
                                        _formatDateHeader(notif.ts),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF7A8699),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  _NotifCard(
                                    notif: notif,
                                    onTap: () => provider.markRead(actualIndex),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar(NotificationProvider provider, Map<String, int> tabCounts) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 0),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1221), // Matching billing_screen.dart dark background
        image: DecorationImage(
          image: AssetImage('assets/images/grid_bg.png'),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar with Back button and Title (Matched with billing_screen / Voucher)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FEBRI.NET',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Notifikasi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (provider.unreadCount > 0)
                  InkWell(
                    onTap: provider.markAllRead,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3642),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF165B6B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TANDAI',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4DB6AC),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Semua Dibaca',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF26C6DA),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
          
          const SizedBox(height: 18),
          
          // Unread Count Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C8D7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00C8D7).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C8D7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.unreadCount} belum dibaca',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00C8D7),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'dari ${provider.notifications.length} notifikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Tabs - Scrollable
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final count = tabCounts[filter] ?? 0;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFF00C8D7) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filter,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF00C8D7) : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3366), // Red badge
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<AppNotification> _getFilteredNotifications(List<AppNotification> allNotifs) {
    if (_selectedFilter == 'Semua') return allNotifs;
    return allNotifs.where((n) {
      final t = n.type ?? 'umum';
      switch (_selectedFilter) {
        case 'Umum':
          return t == 'general' || t == 'umum';
        case 'Tagihan':
          return t == 'billing_due' || t == 'tagihan';
        case 'Pembayaran':
          return t == 'payment_received' || t == 'pembayaran';
        case 'Gangguan':
          return t == 'outage' || t == 'gangguan';
        case 'Instalasi':
          return t == 'request_update' || t == 'instalasi';
        case 'Promo':
          return t == 'promo' || t == 'voucher';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Center(
              child: Icon(
                _selectedFilter == 'Semua' ? FontAwesomeIcons.bellSlash : FontAwesomeIcons.boxOpen,
                size: 32,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kosong',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF2A313C)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Belum ada notifikasi untuk kategori ini.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: const Color(0xFF7A8699)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateString(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.year}-${dt.month}-${dt.day}';
    } catch (_) {
      return '';
    }
  }

  String _formatDateHeader(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'HARI INI';
      }
      
      final diff = now.difference(dt);
      if (diff.inDays == 1 || (diff.inDays == 0 && now.day != dt.day)) {
        return 'KEMARIN';
      }
      
      const months = ['JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI', 'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'HARI INI';
    }
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = _getMeta(notif.type, notif.title);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.transparent : Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread dot indicator (cyan line / dot matching mockup)
              Container(
                width: 6,
                height: notif.isRead ? 0 : 40,
                margin: EdgeInsets.only(right: notif.isRead ? 6 : 10),
                decoration: BoxDecoration(
                  color: notif.isRead ? Colors.transparent : const Color(0xFF00C8D7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              
              // Icon Background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: meta.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: FaIcon(
                    meta.icon, 
                    color: meta.iconColor, 
                    size: 20
                  ),
                ),
              ),
              const SizedBox(width: 14),
              
              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                if (meta.prefixIcon != null)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: FaIcon(meta.prefixIcon, size: 12, color: meta.iconColor),
                                    ),
                                  ),
                                TextSpan(
                                  text: notif.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF141F32), // Dark Navy Text
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notif.ts),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7A8699),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF5D6B82),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta.actionText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              meta.actionText!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF141F32),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 12, color: Color(0xFF141F32)),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotifMeta _getMeta(String? type, String title) {
    // Determine mapping based on the mockups and real data
    final lowerTitle = title.toLowerCase();
    
    // Tagihan / Belum Dibayar (Red)
    if (type == 'billing_due' || type == 'tagihan' || lowerTitle.contains('belum dibayar') || lowerTitle.contains('menunggak')) {
      return _NotifMeta(
        bgColor: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFFF3366),
        icon: FontAwesomeIcons.fileInvoice,
        prefixIcon: FontAwesomeIcons.circleExclamation,
        actionText: 'Bayar Sekarang',
      );
    }
    
    // Tagihan Jatuh Tempo (Yellow)
    if (lowerTitle.contains('jatuh tempo')) {
      return _NotifMeta(
        bgColor: const Color(0xFFFFF7E6),
        iconColor: const Color(0xFFFF9100),
        icon: FontAwesomeIcons.clock,
        actionText: 'Bayar',
      );
    }
    
    // Pembayaran Berhasil / Lunas (Green)
    if (type == 'payment_received' || type == 'pembayaran' || lowerTitle.contains('lunas') || lowerTitle.contains('berhasil')) {
      return _NotifMeta(
        bgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF00C853),
        icon: FontAwesomeIcons.check,
      );
    }
    
    // Voucher Hampir Habis / Dibeli (Cyan / Purple)
    if (type == 'voucher' || lowerTitle.contains('voucher')) {
      if (lowerTitle.contains('dibeli')) {
        return _NotifMeta(
          bgColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFFD500F9),
          icon: FontAwesomeIcons.boltLightning,
          actionText: 'Aktifkan',
        );
      }
      return _NotifMeta(
        bgColor: const Color(0xFFE0F7FA),
        iconColor: const Color(0xFF00B0FF),
        icon: FontAwesomeIcons.boltLightning,
        actionText: 'Perpanjang',
      );
    }
    
    // Gangguan / Speed menurun (Red / Blue)
    if (type == 'outage' || type == 'gangguan' || lowerTitle.contains('gangguan') || lowerTitle.contains('menurun')) {
       if (lowerTitle.contains('selesai')) {
          return _NotifMeta(
            bgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF00C853),
            icon: FontAwesomeIcons.checkDouble,
          );
       }
       if (lowerTitle.contains('menurun')) {
          return _NotifMeta(
            bgColor: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF2979FF),
            icon: FontAwesomeIcons.chartLine,
            actionText: 'Cek Speed',
          );
       }
       return _NotifMeta(
          bgColor: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFFF3366),
          icon: FontAwesomeIcons.triangleExclamation,
       );
    }
    
    // Update Sistem / Maintenance
    if (lowerTitle.contains('update') || lowerTitle.contains('pemeliharaan')) {
      if (lowerTitle.contains('pemeliharaan')) {
        return _NotifMeta(
          bgColor: const Color(0xFFFFF7E6),
          iconColor: const Color(0xFFFF9100),
          icon: FontAwesomeIcons.clock,
        );
      }
      return _NotifMeta(
        bgColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF2979FF),
        icon: FontAwesomeIcons.cube,
        actionText: 'Update',
      );
    }

    // Default (General / Promo)
    return _NotifMeta(
      bgColor: const Color(0xFFE0F7FA),
      iconColor: const Color(0xFF00C8D7),
      icon: FontAwesomeIcons.bell,
    );
  }

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inHours < 24 && dt.day == now.day) {
        // Show time if it's today
        return '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
      }
      // Return empty if not today as we handle dates via the Group Header
      return '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _NotifMeta {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final IconData? prefixIcon;
  final String? actionText;

  _NotifMeta({
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    this.prefixIcon,
    this.actionText,
  });
}
