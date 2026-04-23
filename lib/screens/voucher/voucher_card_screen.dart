import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';

class VoucherCardScreen extends StatelessWidget {
  final String code;
  final String packageName;
  final String speed;
  final dynamic price;

  const VoucherCardScreen({
    super.key,
    required this.code,
    required this.packageName,
    required this.speed,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voucher Internet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildVoucherCard(context),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            packageName.isEmpty ? 'Paket Wi‑Fi' : packageName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            speed.isEmpty ? '-' : speed,
                            style: GoogleFonts.poppins(
                              color: AppTheme.secondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (price != null)
                      Text(
                        'Rp $price',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    SizedBox(
                      height: 18,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 36,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      bottomLeft: Radius.circular(18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 36),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            'KODE VOUCHER',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              letterSpacing: 2,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.04),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  code,
                                  style: GoogleFonts.poppins(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kode disalin')),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: Text(
                                  'Salin',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryColor,
                                  side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

