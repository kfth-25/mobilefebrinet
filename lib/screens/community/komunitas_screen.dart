import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../installation/installation_screen.dart';

class KomunitasScreen extends StatefulWidget {
  const KomunitasScreen({super.key});

  @override
  State<KomunitasScreen> createState() => _KomunitasScreenState();
}

class _KomunitasScreenState extends State<KomunitasScreen> {
  Map<String, dynamic>? _activeSubscription;
  bool _loadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _loadActiveSubscription();
  }

  Future<void> _loadActiveSubscription() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      setState(() => _loadingSubscription = false);
      return;
    }

    try {
      final uri = Uri.parse('${AuthProvider.baseUrl}/subscriptions?status=active');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded.whereType<Map<String, dynamic>>().toList();
          if (mounted) {
            setState(() {
              _activeSubscription = list.isNotEmpty ? list.first : null;
              _loadingSubscription = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _loadingSubscription = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSubscription = false);
    }
  }

  final List<_CommunityPost> _posts = [
    _CommunityPost(
      id: 'post-1',
      author: 'Budi Santoso',
      avatar: 'B',
      avatarColor: Color(0xFFF97316),
      location: 'RT 03 Area A',
      time: '10 menit lalu',
      type: 'Laporan Gangguan',
      typeColor: Color(0xFFEA580C),
      content:
          'Internet di rumah saya putus total dari tadi pagi sekitar jam 06.00. Sudah coba restart modem tapi tetap tidak bisa connect. Ada yang sama?',
      tags: ['RT 03, Area A', 'Tidak ada koneksi', 'Sejak 06.00'],
      impactedCount: 18,
      commentsPreview: 'Halo Pak Budi, tim teknis sedang menangani. Estimasi selesai 2-3 jam.',
    ),
    _CommunityPost(
      id: 'post-2',
      author: 'CS Febri.net',
      avatar: 'CS',
      avatarColor: Color(0xFF3A5BFA),
      location: 'Pengumuman Resmi',
      time: '25 menit lalu',
      type: 'Info Resmi',
      typeColor: Color(0xFF2563EB),
      content:
          'Pemberitahuan pemeliharaan jaringan pukul 22.00–02.00 WIB untuk Area A dan B. Mohon maaf atas ketidaknyamanannya.',
      tags: ['Area A & B', '22.00–02.00 WIB', 'Malam ini'],
      impactedCount: 3,
    ),
    _CommunityPost(
      id: 'post-3',
      author: 'Rudi Hermawan',
      avatar: 'R',
      avatarColor: Color(0xFF7C3AED),
      location: 'RT 02 Area A',
      time: '3 jam lalu',
      type: 'Diskusi',
      typeColor: Color(0xFF06B6D4),
      content:
          'Ada yang tahu paket paling bagus buat streaming 4K? Sekarang pakai 20Mbps tapi sering buffering kalau malam.',
      tags: ['Streaming', 'Tanya paket'],
      impactedCount: 6,
      commentsPreview: 'Coba upgrade ke 50Mbps, biasanya lebih stabil untuk streaming malam.',
    ),
  ];

  final Map<String, List<_CommentItem>> _commentsByPost = {
    'post-1': [
      _CommentItem(
        name: 'Siti Rahayu',
        avatar: 'S',
        avatarColor: Color(0xFFEC4899),
        text: 'Sama, di RT 02 juga putus dari pagi.',
        time: '8 mnt lalu',
      ),
      _CommentItem(
        name: 'CS Febri.net',
        avatar: 'CS',
        avatarColor: Color(0xFF3A5BFA),
        text: 'Laporan sudah diterima, tim teknis on-site.',
        time: '6 mnt lalu',
      ),
    ],
    'post-2': [
      _CommentItem(
        name: 'Ani',
        avatar: 'A',
        avatarColor: Color(0xFF0891B2),
        text: 'Siap, terima kasih infonya.',
        time: '10 mnt lalu',
      ),
    ],
    'post-3': [
      _CommentItem(
        name: 'Hendra',
        avatar: 'H',
        avatarColor: Color(0xFF059669),
        text: 'Saya pakai 50Mbps lancar buat 4K.',
        time: '15 mnt lalu',
      ),
    ],
  };

  int _selectedFilter = 0;

  int _onlineCount = 24;

  void _openComments(_CommunityPost post) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final comments = _commentsByPost[post.id] ?? [];
            void send() {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              setState(() {
                _commentsByPost.putIfAbsent(post.id, () => []);
                _commentsByPost[post.id]!.add(
                  _CommentItem(
                    name: 'Kamu',
                    avatar: 'K',
                    avatarColor: const Color(0xFF00D4C9),
                    text: text,
                    time: 'Baru saja',
                  ),
                );
              });
              controller.clear();
              setLocal(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Komentar • ${post.author}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final c = comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: c.avatarColor,
                                child: Text(
                                  c.avatar,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            c.time,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D4C9),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'K',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF082A3A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar...',
                              hintStyle: GoogleFonts.poppins(fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: send,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00D4C9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF082A3A)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_CommunityPost> get _filteredPosts {
    if (_selectedFilter == 1) {
      return _posts.where((p) => p.type == 'Laporan Gangguan').toList();
    }
    if (_selectedFilter == 2) {
      return _posts.where((p) => p.type == 'Info Resmi').toList();
    }
    if (_selectedFilter == 3) {
      return _posts.where((p) => p.type == 'Diskusi').toList();
    }
    return _posts;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSubscription) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeSubscription == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Komunitas Terbatas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fitur komunitas hanya tersedia bagi pelanggan yang sudah melakukan pemasangan WiFi Febri.net.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InstallationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pasang Sekarang',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filters = ['Semua', 'Gangguan', 'Info', 'Diskusi'];
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B1220),
                    Color(0xFF102536),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5567).withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'Febri.net Area A',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.notifications_none, color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00D4C9),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'K',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF082A3A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'KOMUNITAS',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Jaringan Kamu',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statPill(Icons.people_alt_outlined, 'Online', '$_onlineCount'),
                        const SizedBox(width: 8),
                        _statPill(Icons.warning_amber_rounded, 'Gangguan', '${_posts.where((e) => e.type == 'Laporan Gangguan').length}'),
                        const SizedBox(width: 8),
                        _statPill(Icons.wifi_tethering_error_rounded, 'Terdampak', '${_posts.fold<int>(0, (sum, p) => sum + p.impactedCount)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(filters.length, (i) {
                      final active = _selectedFilter == i;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFilter = i),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              height: 33,
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFF00D4C9).withOpacity(0.16) : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: active ? const Color(0xFF00D4C9).withOpacity(0.65) : Colors.white24,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                filters[i],
                                style: GoogleFonts.poppins(
                                  color: active ? const Color(0xFF78F5F0) : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D4C9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'K',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF082A3A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Laporkan gangguan atau tulis sesuatu...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFB923C), size: 20),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA7F3D0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_onlineCount pengguna online di area kamu',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _OnlineUserChip(name: 'Kamu', avatar: 'K', color: Color(0xFF00D4C9)),
                        _OnlineUserChip(name: 'Budi', avatar: 'B', color: Color(0xFFF59E0B)),
                        _OnlineUserChip(name: 'Siti', avatar: 'S', color: Color(0xFFEC4899)),
                        _OnlineUserChip(name: 'Rudi', avatar: 'R', color: Color(0xFF7C3AED)),
                        _OnlineUserChip(name: 'Ani', avatar: 'A', color: Color(0xFF0EA5E9)),
                        _OnlineUserChip(name: 'Hendra', avatar: 'H', color: Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              child: Column(
                children: _filteredPosts.map(_buildPostCard).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(_CommunityPost post) {
    final comments = _commentsByPost[post.id] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: post.avatarColor,
                child: Text(
                  post.avatar,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '${post.location} • ${post.time}',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: Colors.grey[500]),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: post.typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: post.typeColor.withOpacity(0.2)),
            ),
            child: Text(
              post.type,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: post.typeColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            post.content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: post.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (post.impactedCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Text('😟', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${post.impactedCount} pengguna terdampak',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFEA580C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if ((post.commentsPreview ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                post.commentsPreview!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => post.impactedCount += 1);
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: Text('Terdampak ${post.impactedCount}'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEA580C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openComments(post),
                  icon: const Icon(Icons.mode_comment_outlined, size: 18),
                  label: Text('Komentar ${comments.length}'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link post dibagikan'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined),
                color: const Color(0xFF475569),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OnlineUserChip extends StatelessWidget {
  final String name;
  final String avatar;
  final Color color;

  const _OnlineUserChip({
    required this.name,
    required this.avatar,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              avatar,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPost {
  final String id;
  final String author;
  final String avatar;
  final Color avatarColor;
  final String location;
  final String time;
  final String type;
  final Color typeColor;
  final String content;
  final List<String> tags;
  int impactedCount;
  final String? commentsPreview;

  _CommunityPost({
    required this.id,
    required this.author,
    required this.avatar,
    required this.avatarColor,
    required this.location,
    required this.time,
    required this.type,
    required this.typeColor,
    required this.content,
    required this.tags,
    required this.impactedCount,
    this.commentsPreview,
  });
}

class _CommentItem {
  final String name;
  final String avatar;
  final Color avatarColor;
  final String text;
  final String time;

  _CommentItem({
    required this.name,
    required this.avatar,
    required this.avatarColor,
    required this.text,
    required this.time,
  });
}
