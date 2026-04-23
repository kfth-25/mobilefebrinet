import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _tab = 'cs';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kembali',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.notifications_none, color: Colors.white70),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.secondaryColor,
                            child: Text(
                              'K',
                              style: GoogleFonts.poppins(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip('CS Febri.net', 'cs', true),
                      const SizedBox(width: 8),
                      _buildChip('Sesama Pelanggan', 'peer', false),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: _tab == 'cs' ? _buildCsList() : _buildPeerList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, String value, bool left) {
    final selected = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: selected ? AppTheme.primaryColor : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCsList() {
    return [
      _chatTile(
        initials: 'CS',
        name: 'CS Febri.net',
        message: 'Ada yang bisa kami bantu?',
        time: '09.45',
        color: const Color(0xFF6C63FF),
        unread: 1,
        online: true,
      ),
      _chatTile(
        initials: 'TK',
        name: 'Tim Teknis',
        message: 'Gangguan sudah kami perbaiki.',
        time: 'Kemarin',
        color: const Color(0xFF2E7D6B),
        unread: 0,
        online: false,
      ),
    ];
  }

  List<Widget> _buildPeerList() {
    return [
      _sectionTitle('Grup'),
      _chatTile(
        initials: 'GRP',
        name: 'Grup Febri.net Area A',
        message: 'Budi: Internet lemot gak nih?',
        time: '10.12',
        color: const Color(0xFF7B61FF),
        unread: 5,
        online: true,
      ),
      _sectionTitle('Pesan Langsung'),
      _chatTile(
        initials: 'B',
        name: 'Budi Santoso',
        message: 'Makasih udah share kode voucher!',
        time: '08.30',
        color: const Color(0xFFF3A917),
        unread: 0,
        online: true,
      ),
      _chatTile(
        initials: 'S',
        name: 'Siti Rahayu',
        message: 'Kamu pakai paket yang mana?',
        time: 'Selasa',
        color: const Color(0xFFEA4E8B),
        unread: 0,
        online: false,
      ),
    ];
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          color: AppTheme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _chatTile({
    required String initials,
    required String name,
    required String message,
    required String time,
    required Color color,
    required int unread,
    required bool online,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (online)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 10,
              backgroundColor: AppTheme.secondaryColor,
              child: Text(
                '$unread',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

