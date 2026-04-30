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
        border: Border.all(color: AppColors.border, width: 0.9),
        gradient: const LinearGradient(
          colors: [Color(0xE315262D), Color(0xB70B171C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
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
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(height: 1.12),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  color: statusColor.withValues(alpha: 0.12),
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
                        letterSpacing: 0.9,
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
        return AppColors.goodAccent;
      case 'moderate':
      case 'caution':
        return AppColors.moderateAccent;
      default:
        return AppColors.unhealthyAccent;
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
              color: AppColors.backgroundLift.withValues(alpha: 0.72),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 24,
                  spreadRadius: 1,
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
                    height: 0.95,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'AQI',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
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
      ..color = AppColors.border
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.26), color],
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
