import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/constants/app_colors.dart';

class AqiCard extends StatelessWidget {
  const AqiCard({
    required this.city,
    required this.updatedLabel,
    required this.status,
    required this.message,
    required this.aqi,
    required this.onRefresh,
    super.key,
  });

  final String city;
  final String updatedLabel;
  final String status;
  final String message;
  final int aqi;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          colors: [Color(0xAA0E2F2F), Color(0x44061315)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(height: 1.15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          updatedLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh, size: 18),
                          color: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.65),
                  ),
                  color: statusColor.withValues(alpha: 0.13),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.92),
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          _AqiRing(aqi: aqi, color: statusColor, statusLabel: status),
        ],
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'good':
      case 'safe':
        return AppColors.accent;
      case 'moderate':
      case 'caution':
        return AppColors.moderateAccent;
      default:
        return const Color(0xFFFF6464);
    }
  }
}

class _AqiRing extends StatelessWidget {
  const _AqiRing({
    required this.aqi,
    required this.color,
    required this.statusLabel,
  });

  final int aqi;
  final Color color;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(270),
            painter: _RingPainter(
              progress: (aqi / 300).clamp(0, 1),
              color: color,
            ),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.surface.withValues(alpha: 0.55),
                  AppColors.background,
                ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$aqi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 72,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'AQI',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    letterSpacing: 5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = color.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.15), color],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius - 22))
      ..strokeCap = StrokeCap.round;

    for (final factor in [1.0, 0.86, 0.72]) {
      canvas.drawCircle(
        center,
        (radius - 20) * factor,
        ringPaint..strokeWidth = 1.6,
      );
    }

    final rect = Rect.fromCircle(center: center, radius: radius - 38);
    canvas.drawArc(rect, 0, math.pi * 2, false, ringPaint..strokeWidth = 10);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
