import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// No external dependencies for this specific implementation if we stick to basic widgets,
// but we'll use provider if needed for context. 
// Assuming AppTheme is available.
import '../../utils/app_theme.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> with SingleTickerProviderStateMixin {
  // Test State
  bool _isTesting = false;
  String _status = 'Siap melakukan pengujian';
  double _displaySpeed = 0.0;
  double _gaugeValue = 0.0; // 0.0 to 100.0

  // Results
  String _dlVal = '—';
  String _ulVal = '—';
  String _pingVal = '—';
  String _jitterVal = '—';
  double _dlProgress = 0.0; // 0.0 to 1.0 for bar
  double _ulProgress = 0.0;

  // Animation
  Timer? _testTimer;
  late AnimationController _needleController;

  @override
  void initState() {
    super.initState();
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: -90,
      upperBound: 90,
    );
    // Initial needle position
    _needleController.value = -90; 
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _needleController.dispose();
    super.dispose();
  }

  void _resetUI() {
    setState(() {
      _displaySpeed = 0.0;
      _gaugeValue = 0.0;
      _dlVal = '—';
      _ulVal = '—';
      _pingVal = '—';
      _jitterVal = '—';
      _dlProgress = 0.0;
      _ulProgress = 0.0;
      _status = 'Siap melakukan pengujian';
      _needleController.animateTo(-90, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
    });
  }

  void _runSpeedTest() {
    if (_isTesting) return;

    _resetUI();
    setState(() {
      _isTesting = true;
      _status = 'Mengecek latensi...';
    });

    // Mock Targets
    final dlTarget = 44.0 + math.Random().nextDouble() * 8.0; // 44-52 Mbps
    final ulTarget = 9.0 + math.Random().nextDouble() * 4.0;  // 9-13 Mbps
    final pingTarget = 10 + math.Random().nextInt(8);
    final jitterTarget = 1 + math.Random().nextInt(4);

    // Phase 1: Ping (Simulated delay)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _pingVal = '$pingTarget';
        _jitterVal = '$jitterTarget';
        _status = 'Mengukur kecepatan download...';
      });

      // Phase 2: Download
      double t = 0;
      _testTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
        t += 0.04;
        
        // Curve simulation
        double v = dlTarget * (1 - math.exp(-t * 2));
        
        if (mounted) {
          setState(() {
            _displaySpeed = v;
            _gaugeValue = (v / 100) * 100;
            _dlProgress = math.min(v / 100, 1.0); // Assuming 100Mbps max for bar
            
            // Update needle angle (-90 to 90)
            // 0 Mbps = -90 deg
            // 100 Mbps = 90 deg
            double angle = -90 + (_gaugeValue * 1.8);
            _needleController.value = angle;
          });
        }

        if (t >= 2.0) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _dlVal = dlTarget.toStringAsFixed(1);
              _displaySpeed = 0.0;
              _gaugeValue = 0.0;
              _needleController.animateTo(-90, duration: const Duration(milliseconds: 400));
              _status = 'Mengukur kecepatan upload...';
            });
            
            // Phase 3: Upload
            Future.delayed(const Duration(milliseconds: 600), () {
               _startUploadTest(ulTarget);
            });
          }
        }
      });
    });
  }

  void _startUploadTest(double ulTarget) {
    double t = 0;
    _testTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      t += 0.05;
      double v = ulTarget * (1 - math.exp(-t * 2));

      if (mounted) {
        setState(() {
          _displaySpeed = v;
          _gaugeValue = (v / 100) * 100;
          _ulProgress = math.min(v / 100, 1.0);
          
          double angle = -90 + (_gaugeValue * 1.8);
          _needleController.value = angle;
        });
      }

      if (t >= 2.0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _ulVal = ulTarget.toStringAsFixed(1);
            _isTesting = false;
            _status = '✓ Selesai';
            // Keep needle at result or reset? Usually reset or stay. 
            // Design shows needle resetting or staying at final. Let's keep it at final for a moment then reset?
            // Actually the reference implementation resets it partially or shows summary.
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      body: Column(
        children: [
          // 1. Header & Gauge Section
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Gradient Background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0B1221),
                          Color(0xFF162033),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 20,
                        left: 24,
                        right: 24,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.09)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FEBRI.NET',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white38,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'Speed Test',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.22)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'SERVER',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white38,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  'Majalengka',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF60A5FA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Gauge
                    SizedBox(
                      width: 260,
                      height: 200, // Reduced height as it's a semi-circle
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(260, 260),
                            painter: _GaugePainter(value: _gaugeValue),
                          ),
                          // Display Text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40), // Push down below arch
                              Text(
                                _displaySpeed.toStringAsFixed(1),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'Mbps',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white38,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _status,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _isTesting ? Colors.white70 : (_status.contains('Selesai') ? AppTheme.primaryColor : Colors.white38),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Start Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isTesting ? null : _runSpeedTest,
                          icon: Icon(_status.contains('Selesai') ? Icons.refresh : Icons.play_arrow_rounded, size: 20),
                          label: Text(_status.contains('Selesai') ? 'Ulangi Test' : 'Mulai Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB), // Blue button
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Stats & History Section (White Sheet)
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DL / UL Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Download',
                            _dlVal,
                            'Mbps',
                            _dlProgress,
                            const Color(0xFF2563EB),
                            Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Upload',
                            _ulVal,
                            'Mbps',
                            _ulProgress,
                            const Color(0xFF059669), // Green
                            Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Ping & Jitter
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallStatCard('PING', _pingVal, 'ms', 'Sangat Baik', Colors.green),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSmallStatCard('JITTER', _jitterVal, 'ms', 'Stabilitas koneksi', Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard('PAKET AKTIF', '50 Mbps', 'Family 30 hari'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard('IP PUBLIK', '182.x.x.x', 'Dinamis'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // History
                    Text(
                      'Riwayat Test',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A0F1E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHistoryItem(
                      date: 'Hari ini, 15.22',
                      ping: '12ms',
                      jitter: '2ms',
                      dl: '48.3',
                      ul: '11.2',
                      color: const Color(0xFF2563EB),
                    ),
                    _buildHistoryItem(
                      date: 'Kemarin, 20.10',
                      ping: '15ms',
                      jitter: '3ms',
                      dl: '46.7',
                      ul: '10.8',
                      color: const Color(0xFF059669),
                    ),
                    _buildHistoryItem(
                      date: '6 Mar, 09.45',
                      ping: '28ms',
                      jitter: '8ms',
                      dl: '31.4',
                      ul: '8.1',
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String val, String unit, double progress, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress == 0 ? 0.05 : progress, // Min width visual
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String val, String unit, String sub, Color badgeColor) {
    bool isGood = sub == 'Sangat Baik';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                val,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0A0F1E),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isGood)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sub,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green),
              ),
            )
          else
            Text(
              sub,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String main, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            main,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A0F1E),
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String date,
    required String ping,
    required String jitter,
    required String dl,
    required String ul,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0F1E),
                  ),
                ),
                Text(
                  'Ping ${ping} · Jitter ${jitter}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    dl,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_downward_rounded, size: 12, color: Color(0xFF2563EB)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    ul,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF059669)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// PAINTERS for GAUGE & GRID
class _GaugePainter extends CustomPainter {
  final double value; // 0 to 100
  _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85); // Pivot at bottom center
    final radius = size.width * 0.45;
    
    final paintTrack = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // Draw Track Arc (from -180 to 0 degrees, essentially a semi-circle arch)
    // Actually typically gauges go from like 135 to 45 deg or -180 to 0.
    // Let's do -180 to 0 (PI to 2PI in radians)
    // Flutter 0 is right (3 o'clock). 
    // -PI is left (9 o'clock).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start at 9 o'clock
      math.pi, // Sweep 180 deg to 3 o'clock
      false,
      paintTrack,
    );

    // Draw Colored Arc
    final paintFill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFF2563EB), Color(0xFF00C8D7), Color(0xFF00D4A0)],
        startAngle: math.pi,
        endAngle: 2 * math.pi,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Calculate sweep angle based on value (0-100)
    // Max sweep is PI
    final sweepAngle = (value / 100) * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      paintFill,
    );

    // Draw Needle
    // Angle in radians.
    // 0 value = PI (9 o'clock)
    // 100 value = 2PI (3 o'clock)
    final needleAngle = math.pi + sweepAngle;

    final needleLen = radius - 10;
    final needleEnd = Offset(
      center.dx + needleLen * math.cos(needleAngle),
      center.dy + needleLen * math.sin(needleAngle),
    );

    final paintNeedle = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, paintNeedle);

    // Needle pivot circle
    canvas.drawCircle(center, 6, paintNeedle);

    // Labels (Simple 0, 50, 100)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    _drawLabel(canvas, textPainter, '0', center, radius + 25, math.pi);
    _drawLabel(canvas, textPainter, '50', center, radius + 25, math.pi * 1.5);
    _drawLabel(canvas, textPainter, '100', center, radius + 25, math.pi * 2);
  }

  void _drawLabel(Canvas canvas, TextPainter tp, String text, Offset center, double radius, double angle) {
    tp.text = TextSpan(
      text: text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.3),
      ),
    );
    tp.layout();
    final pos = Offset(
      center.dx + radius * math.cos(angle) - tp.width / 2,
      center.dy + radius * math.sin(angle) - tp.height / 2,
    );
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.value != value;
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
