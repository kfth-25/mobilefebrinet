import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

// ─── Color tokens (from CSS :root) ───────────────────────────────────────────
const _ink = Color(0xFF080f20);
const _bg = Color(0xFFF2F4F9);
const _white = Color(0xFFFFFFFF);
const _bd = Color(0xFFE4E9F4);
const _aqua = Color(0xFF00C8D7);
const _aqua2 = Color(0xFF00EEFF);
const _mint = Color(0xFF00D4A0);
const _red = Color(0xFFE11D48);
const _amber = Color(0xFFD97706);
const _green = Color(0xFF059669);
const _blue = Color(0xFF2563EB);
const _violet = Color(0xFF5B21B6);
const _t1 = Color(0xFF0A0F1E);
const _t2 = Color(0xFF374151);
const _t3 = Color(0xFF6B7280);
const _t4 = Color(0xFF9CA3AF);

// ─── Models ──────────────────────────────────────────────────────────────────
enum AktivitasType { tagihan, voucher, topup, transfer, bonus, lock }

class AktivitasItem {
  final String title;
  final String subtitle;
  final String? note;
  final String amount;
  final bool isIncome; // false = keluar/merah, true = masuk/hijau, null = belum bayar
  final bool isBillPending;
  final String? status; // 'LUNAS', 'BELUM BAYAR', 'DIPEGANG', 'HABIS', 'JATUH TEMPO'
  final AktivitasType type;

  const AktivitasItem({
    required this.title,
    required this.subtitle,
    this.note,
    required this.amount,
    required this.isIncome,
    this.isBillPending = false,
    this.status,
    required this.type,
  });
}

class AktivitasGroup {
  final String month;
  final List<AktivitasItem> items;
  const AktivitasGroup(this.month, this.items);
}

// ─── Mock data ────────────────────────────────────────────────────────────────
final _dataSemua = [
  AktivitasGroup('Maret 2026', [
    AktivitasItem(title: 'Tagihan Bulanan', subtitle: '1 Mar 2026 · Jatuh tempo 25 Mar', amount: 'Rp 150.000', isIncome: false, isBillPending: true, status: 'BELUM BAYAR', type: AktivitasType.tagihan),
    AktivitasItem(title: 'Beli Voucher Family 50Mbps', subtitle: '2 Mar 2026 · 09.15 · FebriPay', note: '7 hari · Kode: FBR-2026-F4M1', amount: '−Rp 55.000', isIncome: false, status: 'Berhasil ✓', type: AktivitasType.voucher),
    AktivitasItem(title: 'Top Up FebriPay', subtitle: '5 Mar 2026 · 14.32 · QRIS', amount: '+Rp 100.000', isIncome: true, status: 'Berhasil ✓', type: AktivitasType.topup),
  ]),
  AktivitasGroup('Februari 2026', [
    AktivitasItem(title: 'Tagihan Bulanan', subtitle: '10 Feb 2026 · FebriPay', amount: '−Rp 150.000', isIncome: false, status: 'LUNAS', type: AktivitasType.tagihan),
    AktivitasItem(title: 'Bonus Referral', subtitle: '20 Feb 2026 · Dari: @budi', amount: '+Rp 15.000', isIncome: true, status: 'Bonus ✓', type: AktivitasType.bonus),
    AktivitasItem(title: 'Transfer ke @budi', subtitle: '24 Feb 2026 · 18.00 · FebriPay', amount: '−Rp 20.000', isIncome: false, status: 'Berhasil ✓', type: AktivitasType.transfer),
    AktivitasItem(title: 'Beli Voucher Turbo 100Mbps', subtitle: '26 Feb 2026 · 09.15 · FebriPay', note: '7 hari · Dipegang (belum dipakai)', amount: '−Rp 70.000', isIncome: false, status: 'Berhasil ✓', type: AktivitasType.voucher),
    AktivitasItem(title: 'Top Up FebriPay', subtitle: '28 Feb 2026 · 14.32 · QRIS', amount: '+Rp 50.000', isIncome: true, status: 'Berhasil ✓', type: AktivitasType.topup),
    AktivitasItem(title: 'Top Up Virtual Account', subtitle: '15 Feb 2026 · 10.45 · BCA', amount: '+Rp 100.000', isIncome: true, status: 'Berhasil ✓', type: AktivitasType.lock),
  ]),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class AktivitasScreen extends StatefulWidget {
  const AktivitasScreen({super.key});

  @override
  State<AktivitasScreen> createState() => _AktivitasScreenState();
}

class _AktivitasScreenState extends State<AktivitasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = ['Semua', 'Transaksi', 'Tagihan', 'Voucher'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _DarkHeader(tabController: _tabController, tabs: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TabSemua(),
                _TabTransaksi(),
                _TabTagihan(),
                _TabVoucher(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DARK HEADER ─────────────────────────────────────────────────────────────
class _DarkHeader extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;

  const _DarkHeader({required this.tabController, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MARET 2026',
                            style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            )),
                        const SizedBox(height: 2),
                        Text('Aktivitas',
                            style: GoogleFonts.poppins(
                              fontSize: 24, fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                  // Filter + Search buttons
                  Row(
                    children: [
                      _HeaderIconBtn(icon: Icons.tune_rounded),
                      const SizedBox(width: 8),
                      _HeaderIconBtn(icon: Icons.search_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: const [
                  Expanded(child: _StatCard(label: 'Total Keluar', value: '355rb', color: Color(0xFFF87171), sub: '7 transaksi')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Total Masuk', value: '165rb', color: Color(0xFF34D399), sub: '3 transaksi')),
                  SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Tagihan', value: '150rb', color: Color(0xFFFBBF24), sub: 'Belum bayar')),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: tabController,
              tabs: tabs.map((t) => Tab(text: t)).toList(),
              labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              labelColor: AppTheme.secondaryColor,
              unselectedLabelColor: Colors.white.withOpacity(0.45),
              indicatorColor: AppTheme.secondaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2,
              dividerColor: Colors.white.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  const _HeaderIconBtn({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      );
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white60)),
            const SizedBox(height: 5),
            Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(sub, style: GoogleFonts.poppins(fontSize: 9, color: Colors.white38)),
          ],
        ),
      );
}

// ─── TAB: SEMUA ──────────────────────────────────────────────────────────────
class _TabSemua extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        // Tagihan banner
        _BillWarningBanner(),
        // Month groups
        ..._dataSemua.asMap().entries.map((e) {
          final idx = e.key;
          final group = e.value;
          return _MonthGroup(
            month: group.month,
            count: '${group.items.length} aktivitas',
            accentColor: idx == 0 ? _aqua : const Color(0xFFA78BFA),
            items: group.items,
          );
        }),
        _LoadMoreBtn(),
      ],
    );
  }
}

// ─── TAB: TRANSAKSI ──────────────────────────────────────────────────────────
class _TabTransaksi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        // Saldo mini card
        Container(
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF060F28), Color(0xFF0C1E46)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _blue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SALDO FEBRIPAY', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.35), letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text('Rp 85.500', style: GoogleFonts.jetBrainsMono(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _MiniBtn(label: '+ Top Up', color: _blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniBtn(label: 'Transfer →', color: Colors.white.withOpacity(0.6))),
                ],
              )
            ],
          ),
        ),
        _MonthGroupSimple(month: 'Maret 2026', count: '3 transaksi', accentColor: _aqua, items: [
          _TrxItem(title: 'Top Up QRIS', sub: '5 Mar 2026 · 14.32', amount: '+Rp 100.000', isIncome: true, status: 'Berhasil ✓', type: AktivitasType.topup),
          _TrxItem(title: 'Beli Voucher Family 50Mbps', sub: '2 Mar 2026 · 09.15', amount: '−Rp 55.000', isIncome: false, status: 'Berhasil ✓', type: AktivitasType.voucher),
          _TrxItem(title: 'Tagihan Bulanan', sub: 'Belum dibayar · jt 25 Mar', amount: 'Rp 150.000', isIncome: false, status: 'JATUH TEMPO', type: AktivitasType.tagihan, isPending: true),
        ]),
        _MonthGroupSimple(month: 'Februari 2026', count: '5 transaksi', accentColor: const Color(0xFFA78BFA), items: [
          _TrxItem(title: 'Top Up Virtual Account', sub: '28 Feb 2026 · BCA', amount: '+Rp 100.000', isIncome: true, status: 'Berhasil ✓', type: AktivitasType.lock),
          _TrxItem(title: 'Transfer ke @budi', sub: '24 Feb 2026 · 18.00', amount: '−Rp 20.000', isIncome: false, status: 'Berhasil ✓', type: AktivitasType.transfer),
          _TrxItem(title: 'Bonus Referral', sub: '20 Feb 2026 · dari @budi', amount: '+Rp 15.000', isIncome: true, status: 'Bonus ✓', type: AktivitasType.bonus),
          _TrxItem(title: 'Tagihan Bulanan', sub: '10 Feb 2026 · FebriPay', amount: '−Rp 150.000', isIncome: false, status: 'Lunas ✓', type: AktivitasType.tagihan),
          _TrxItem(title: 'Top Up QRIS', sub: '5 Feb 2026 · 11.20', amount: '+Rp 50.000', isIncome: true, status: 'Berhasil ✓', type: AktivitasType.topup),
        ]),
        _LoadMoreBtn(),
      ],
    );
  }
}

// ─── TAB: TAGIHAN ────────────────────────────────────────────────────────────
class _TabTagihan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        // Active bill card
        Container(
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B0A18), Color(0xFF7F1D1D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _red.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TAGIHAN AKTIF', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.35), letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text('Rp 150.000', style: GoogleFonts.jetBrainsMono(fontSize: 22, fontWeight: FontWeight.w800, color: _white, letterSpacing: -1)),
                      const SizedBox(height: 4),
                      Text('Jatuh tempo 25 Maret 2026', style: GoogleFonts.sora(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.18),
                      border: Border.all(color: _red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('BELUM BAYAR', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFF87171))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(flex: 2, child: _RedBtn(label: 'Bayar Sekarang')),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.6),
                      side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: Text('Detail', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700)),
                  )),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _SectionHeader(label: 'Riwayat Tagihan', accentColor: _amber),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              _BillCard(month: 'Maret 2026', status: 'BELUM BAYAR', isPending: true,
                  paket: 'Family 50Mbps', periode: '1–31 Mar 2026', amount: 'Rp 150.000', jatuhTempo: '25 Mar 2026', metode: null, dibayar: null),
              const SizedBox(height: 9),
              _BillCard(month: 'Februari 2026', status: 'LUNAS', isPending: false,
                  paket: 'Family 50Mbps', periode: null, amount: 'Rp 150.000', jatuhTempo: null, metode: 'FebriPay', dibayar: '10 Feb 2026'),
              const SizedBox(height: 9),
              _BillCard(month: 'Januari 2026', status: 'LUNAS', isPending: false,
                  paket: 'Family 50Mbps', periode: null, amount: 'Rp 150.000', jatuhTempo: null, metode: 'Transfer BCA', dibayar: '8 Jan 2026'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _LoadMoreBtn(),
      ],
    );
  }
}

// ─── TAB: VOUCHER ────────────────────────────────────────────────────────────
class _TabVoucher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        // Active voucher card
        Container(
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF003C45), Color(0xFF005A6B), Color(0xFF002C35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _aqua.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VOUCHER AKTIF', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.35), letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text('Family Entertainment', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _white)),
                      Text('50 Mbps', style: GoogleFonts.jetBrainsMono(fontSize: 22, fontWeight: FontWeight.w800, color: _aqua, letterSpacing: -0.5)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _aqua.withOpacity(0.15),
                      border: Border.all(color: _aqua.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('AKTIF', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: _aqua)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sisa waktu', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.45))),
                  Text('18 hari tersisa', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: _aqua)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00C8D7)),
                ),
              ),
              const SizedBox(height: 8),
              Text('Berlaku hingga 26 Mar 2026 · Kode: FBR-2026-F4M1',
                  style: GoogleFonts.sora(fontSize: 11, color: Colors.white.withOpacity(0.35))),
            ],
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Row(
            children: [
              Expanded(child: _WhiteOutlineBtn(label: 'Beli Voucher', iconColor: _aqua, iconData: Icons.bolt_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _WhiteOutlineBtn(label: 'Redeem Kode', iconColor: _green, iconData: Icons.lock_open_rounded)),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _SectionHeader(label: 'Voucher Dipegang', accentColor: _aqua),
        ),

        // Dipegang
        Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.25), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _violet.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFFA78BFA), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Turbo 100Mbps · 7 hari', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _t1)),
                      const SizedBox(height: 2),
                      Text('Dibeli 26 Feb 2026 · Belum dipakai', style: GoogleFonts.sora(fontSize: 11, color: _t3)),
                      const SizedBox(height: 2),
                      Text('FBR-2026-TRB7', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _t4)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
                    child: Text('DIPEGANG', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w700, color: _amber)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFFA855F7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(foregroundColor: _white, padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: Text('Aktifkan Sekarang', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _white)),
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: _SectionHeader(label: 'Riwayat Voucher', accentColor: _t4),
        ),

        ...[
          ('Family 50Mbps · 30 hari', 'Aktif 20 Jan–20 Feb 2026', 'FBR-2026-FAM2'),
          ('Starter 20Mbps · 7 hari', 'Aktif 10–17 Jan 2026', 'FBR-2026-STR3'),
          ('Family 50Mbps · 30 hari', 'Aktif 20 Des 2025–20 Jan 2026', 'FBR-2025-FAM9'),
        ].map((v) => _ExpiredVoucherTile(title: v.$1, sub: v.$2, code: v.$3)),

        _LoadMoreBtn(),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _BillWarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3B0A18), Color(0xFF7F1D1D)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _red.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: _red.withOpacity(0.15), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tagihan Maret Belum Dibayar', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _white)),
                const SizedBox(height: 2),
                Text('Jatuh tempo 25 Mar 2026 · Rp 150.000', style: GoogleFonts.sora(fontSize: 11, color: Colors.white.withOpacity(0.45))),
              ],
            )),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.2),
                border: Border.all(color: _red.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Bayar', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFF87171))),
            ),
          ],
        ),
      );
}

class _MonthGroup extends StatelessWidget {
  final String month, count;
  final Color accentColor;
  final List<AktivitasItem> items;

  const _MonthGroup({required this.month, required this.count, required this.accentColor, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 7),
                Text(month, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _t1)),
                const Spacer(),
                Text(count, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: _t3)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AktivitasTile(item: item),
            )),
          ],
        ),
      );
}

class _AktivitasTile extends StatelessWidget {
  final AktivitasItem item;
  const _AktivitasTile({required this.item});

  (Color, Color, IconData) get _iconStyle {
    switch (item.type) {
      case AktivitasType.tagihan: return item.isBillPending ? (const Color(0xFFFEE2E2), _red, Icons.description_rounded) : (const Color(0xFFD1FAE5), _green, Icons.task_alt_rounded);
      case AktivitasType.voucher: return (const Color(0xFF00C8D7).withOpacity(0.1), _aqua, Icons.bolt_rounded);
      case AktivitasType.topup: return (const Color(0xFFD1FAE5), _green, Icons.arrow_upward_rounded);
      case AktivitasType.transfer: return (const Color(0xFFDBEAFE), _blue, Icons.arrow_forward_rounded);
      case AktivitasType.bonus: return (const Color(0xFFFBBF24).withOpacity(0.12), _amber, Icons.shield_rounded);
      case AktivitasType.lock: return (const Color(0xFFD1FAE5), _green, Icons.lock_open_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, iconColor, icon) = _iconStyle;
    final amountColor = item.isBillPending ? _red : (item.isIncome ? _green : _red);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isBillPending ? const Color(0xFFFEF2F2) : _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.isBillPending ? _red.withOpacity(0.15) : _bd),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _t1)),
              const SizedBox(height: 2),
              Text(item.subtitle, style: GoogleFonts.sora(fontSize: 11, color: _t3)),
              if (item.note != null) ...[
                const SizedBox(height: 3),
                Text(item.note!, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: _t3)),
              ],
              if (item.status != null && (item.status == 'LUNAS' || item.status == 'BELUM BAYAR')) ...[
                const SizedBox(height: 4),
                _Badge(label: item.status!, color: item.status == 'LUNAS' ? _green : _red),
              ],
            ],
          )),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.amount, style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: amountColor)),
              if (item.status != null && item.status != 'LUNAS' && item.status != 'BELUM BAYAR')
                Text(item.status!, style: GoogleFonts.sora(fontSize: 10, color: _t4)),
            ],
          ),
        ],
      ),
    );
  }
}

// Simplified version for Transaksi tab
class _TrxItem {
  final String title, sub, amount, status;
  final bool isIncome, isPending;
  final AktivitasType type;
  const _TrxItem({required this.title, required this.sub, required this.amount, required this.isIncome, required this.status, required this.type, this.isPending = false});
}

class _MonthGroupSimple extends StatelessWidget {
  final String month, count;
  final Color accentColor;
  final List<_TrxItem> items;
  const _MonthGroupSimple({required this.month, required this.count, required this.accentColor, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 14, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 7),
                Text(month, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w800, color: _t1)),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: _bd)),
                const SizedBox(width: 8),
                Text(count, style: GoogleFonts.sora(fontSize: 10, color: _t3)),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map((item) {
              final (bg, iconColor, icon) = _iconForType(item.type, item.isIncome, item.isPending);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: item.isPending ? const Color(0xFFFEF2F2).withOpacity(0.6) : _white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: item.isPending ? _red.withOpacity(0.2) : _bd),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1))],
                ),
                child: Row(
                  children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: iconColor, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _t1)),
                      Text(item.sub, style: GoogleFonts.sora(fontSize: 11, color: item.isPending ? _red.withOpacity(0.8) : _t3)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(item.amount, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w800, color: item.isPending ? _red : (item.isIncome ? _green : _red))),
                      Text(item.status, style: GoogleFonts.sora(fontSize: 10, fontWeight: item.status == 'JATUH TEMPO' ? FontWeight.w700 : FontWeight.w400, color: item.status == 'JATUH TEMPO' ? _red : _t4)),
                    ]),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
}

(Color, Color, IconData) _iconForType(AktivitasType type, bool isIncome, bool isPending) {
  switch (type) {
    case AktivitasType.tagihan: return isPending ? (const Color(0xFFFEE2E2), _red, Icons.description_rounded) : (const Color(0xFFD1FAE5), _green, Icons.task_alt_rounded);
    case AktivitasType.voucher: return (_aqua.withOpacity(0.1), _aqua, Icons.bolt_rounded);
    case AktivitasType.topup: return (const Color(0xFFD1FAE5), _green, Icons.arrow_upward_rounded);
    case AktivitasType.transfer: return (const Color(0xFFDBEAFE), _blue, Icons.arrow_forward_rounded);
    case AktivitasType.bonus: return (_amber.withOpacity(0.12), _amber, Icons.shield_rounded);
    case AktivitasType.lock: return (const Color(0xFFD1FAE5), _green, Icons.lock_open_rounded);
  }
}

class _BillCard extends StatelessWidget {
  final String month, status;
  final bool isPending;
  final String paket, amount;
  final String? periode, jatuhTempo, metode, dibayar;

  const _BillCard({required this.month, required this.status, required this.isPending, required this.paket, required this.amount, this.periode, this.jatuhTempo, this.metode, this.dibayar});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPending ? _red.withOpacity(0.2) : _bd, width: isPending ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(month, style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: _t1)),
              _Badge(label: status, color: isPending ? _red : _green),
            ]),
            const SizedBox(height: 10),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _GridCell(label: 'Paket', value: paket, valueColor: _t1)),
                    const SizedBox(width: 8),
                    Expanded(child: periode != null
                        ? _GridCell(label: 'Periode', value: periode!, valueColor: _t1)
                        : dibayar != null
                            ? _GridCell(label: 'Dibayar', value: dibayar!, valueColor: _green)
                            : const SizedBox()),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _GridCell(label: isPending ? 'Tagihan' : 'Total', value: amount, valueColor: _t1, isMono: true)),
                    const SizedBox(width: 8),
                    Expanded(child: jatuhTempo != null
                        ? _GridCell(label: 'Jatuh Tempo', value: jatuhTempo!, valueColor: _red, bgColor: const Color(0xFFFEE2E2))
                        : metode != null
                            ? _GridCell(label: 'Metode', value: metode!, valueColor: _green, bgColor: const Color(0xFFD1FAE5))
                            : const SizedBox()),
                  ],
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              _RedBtn(label: 'Bayar Rp 150.000'),
            ],
          ],
        ),
      );
}

class _GridCell extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final Color? bgColor;
  final bool isMono;
  const _GridCell({required this.label, required this.value, required this.valueColor, this.bgColor, this.isMono = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: bgColor ?? _bg, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: GoogleFonts.sora(fontSize: 10, color: _t3)),
          const SizedBox(height: 2),
          Text(value, style: isMono
              ? GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w800, color: valueColor)
              : GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor)),
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color accentColor;
  const _SectionHeader({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 7),
            Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w800, color: _t1)),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

class _RedBtn extends StatelessWidget {
  final String label;
  const _RedBtn({required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFF87171)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: _white, padding: const EdgeInsets.symmetric(vertical: 11)),
            child: Text(label, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _white)),
          ),
        ),
      );
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBtn({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor: _blue.withOpacity(0.18),
          side: BorderSide(color: _blue.withOpacity(0.28)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 9),
        ),
        child: Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      );
}

class _WhiteOutlineBtn extends StatelessWidget {
  final String label;
  final Color iconColor;
  final IconData iconData;
  const _WhiteOutlineBtn({required this.label, required this.iconColor, required this.iconData});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(iconData, size: 15, color: iconColor),
        label: Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _t1)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _bd),
          backgroundColor: _white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.06),
        ),
      );
}

class _LoadMoreBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _bd, width: 1.5),
              shape: StadiumBorder(),
              foregroundColor: _t3,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            ),
            child: Text('Muat lebih banyak ↓', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _t3)),
          ),
        ),
      );
}

class _ExpiredVoucherTile extends StatelessWidget {
  final String title, sub, code;
  const _ExpiredVoucherTile({required this.title, required this.sub, required this.code});

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.7,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _bd),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
          ),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.bolt_rounded, color: _t4, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _t2)),
                const SizedBox(height: 2),
                Text(sub, style: GoogleFonts.sora(fontSize: 11, color: _t3)),
                const SizedBox(height: 2),
                Text(code, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _t4)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
                child: Text('HABIS', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w700, color: _t3)),
              ),
            ],
          ),
        ),
      );
}
