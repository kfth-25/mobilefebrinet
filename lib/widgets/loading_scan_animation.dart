import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class LoadingScanAnimation extends StatefulWidget {
  final double size;
  final String? label;

  const LoadingScanAnimation({
    super.key,
    this.size = 100,
    this.label,
  });

  @override
  State<LoadingScanAnimation> createState() => _LoadingScanAnimationState();
}

class _LoadingScanAnimationState extends State<LoadingScanAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: 3.seconds,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final accent = AppTheme.secondaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Elegant outer ripple (Radar feel)
              Container(
                width: widget.size * 1.3,
                height: widget.size * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.4, 1.4), duration: 2.seconds, curve: Curves.easeOutExpo)
               .fadeOut(duration: 2.seconds),

              // 2. WiFi Icon with Bottom-to-Top Fill Effect
              Animate(
                onPlay: (c) => c.repeat(),
                effects: [
                  CustomEffect(
                    duration: 2.seconds,
                    curve: Curves.easeInOutSine,
                    builder: (context, value, child) {
                      return ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              accent, // Active color
                              accent.withOpacity(0.9),
                              primary.withOpacity(0.08), // Base color
                            ],
                            stops: [
                              0.0,
                              value,
                              value + 0.05,
                            ],
                          ).createShader(rect);
                        },
                        child: child,
                      );
                    },
                  ),
                ],
                child: Icon(
                  Icons.wifi_rounded,
                  size: widget.size,
                  color: Colors.white, // Masked by Shader
                ),
              ),

              // 3. Orbiting scanning dot
              RotationTransition(
                turns: _controller,
                child: SizedBox(
                  width: widget.size * 1.4,
                  height: widget.size * 1.4,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: (widget.size * 1.4) / 2 - 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 32),
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: primary.withOpacity(0.8),
              letterSpacing: 0.8,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .fadeIn(duration: 1.seconds)
           .moveY(begin: 0, end: -3, duration: 1.seconds, curve: Curves.easeInOut),
        ],
      ],
    );
  }
}
