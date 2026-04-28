import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  static const _aqi = 82;
  static const _status = 'Moderate';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth > 440
              ? 440.0
              : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Air Quality Detail',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SummaryCard(),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'POLLUTANTS'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: const [
                      _PollutantCard(
                        name: 'PM2.5',
                        value: 35,
                        max: 150,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'PM10',
                        value: 62,
                        max: 250,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'NO₂',
                        value: 40,
                        max: 200,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'O₃',
                        value: 74,
                        max: 240,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'SO₂',
                        value: 18,
                        max: 100,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'CO',
                        value: 1.2,
                        max: 10,
                        unit: 'mg/m³',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel(label: '7-DAY FORECAST'),
                  const SizedBox(height: 10),
                  const SizedBox(
                    height: 126,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ForecastChip(
                            day: 'Today',
                            level: _ForecastLevel.moderate,
                            label: '⚠',
                            active: true,
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _ForecastChip(
                            day: 'Tue',
                            level: _ForecastLevel.good,
                            label: 'OK',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _ForecastChip(
                            day: 'Wed',
                            level: _ForecastLevel.moderate,
                            label: '⚠',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _ForecastChip(
                            day: 'Thu',
                            level: _ForecastLevel.good,
                            label: 'OK',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _ForecastChip(
                            day: 'Fri',
                            level: _ForecastLevel.good,
                            label: 'OK',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _ForecastChip(
                            day: 'Sat',
                            level: _ForecastLevel.moderate,
                            label: '⚠',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        letterSpacing: 3.6,
        color: AppColors.textSecondary.withValues(alpha: 0.9),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          colors: [Color(0x990E3533), Color(0x33081114)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const _SummaryRing(aqi: DetailPage._aqi),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DetailPage._status.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.moderateAccent,
                    fontSize: 24,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Air quality is acceptable.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sensitive groups should reduce prolonged outdoor exposure.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  'Source: CAMS + WAQI Station',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
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

class _SummaryRing extends StatelessWidget {
  const _SummaryRing({required this.aqi});

  final int aqi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(112),
            painter: _SummaryRingPainter(progress: (aqi / 300).clamp(0, 1)),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xCC081316),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$aqi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 38,
                color: AppColors.moderateAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRingPainter extends CustomPainter {
  const _SummaryRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white12
      ..strokeCap = StrokeCap.round;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0x55FFC947), AppColors.moderateAccent],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _SummaryRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PollutantCard extends StatelessWidget {
  const _PollutantCard({
    required this.name,
    required this.value,
    required this.max,
    required this.unit,
  });

  final String name;
  final double value;
  final double max;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = (value / max).clamp(0, 1).toDouble();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                ),
              ),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ForecastLevel { good, moderate }

class _ForecastChip extends StatelessWidget {
  const _ForecastChip({
    required this.day,
    required this.level,
    required this.label,
    this.active = false,
  });

  final String day;
  final _ForecastLevel level;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final dotColor = level == _ForecastLevel.good
        ? AppColors.accent
        : AppColors.moderateAccent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? dotColor.withValues(alpha: 0.7) : AppColors.border,
        ),
        gradient: LinearGradient(
          colors: active
              ? [AppColors.moderateSoft, const Color(0x330A1A1D)]
              : const [Color(0x550B1C1E), Color(0x22071315)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dotColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
