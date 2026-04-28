import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../air_quality/domain/aqi_calculator.dart';
import '../air_quality/domain/air_quality_model.dart';
import '../air_quality/presentation/air_quality_controller.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AirQualityController>();
    final data = controller.data;

    if (data == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

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
                  _SummaryCard(data: data),
                  const SizedBox(height: 20),
                  const _SectionLabel(label: 'POLLUTANTS'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      _PollutantCard(
                        name: 'PM2.5',
                        value: data.pm25,
                        max: 150,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'PM10',
                        value: data.pm10,
                        max: 250,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'NO₂',
                        value: data.no2,
                        max: 200,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'O₃',
                        value: data.o3,
                        max: 240,
                        unit: 'µg/m³',
                      ),
                      _PollutantCard(
                        name: 'UV INDEX',
                        value: data.uvIndex,
                        max: 12,
                        unit: 'index',
                      ),
                      _PollutantCard(
                        name: 'WIND',
                        value: data.windSpeed,
                        max: 60,
                        unit: 'km/h',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel(
                    label:
                        '${data.forecast7Days.length}-DAY FORECAST',
                  ),
                  const SizedBox(height: 10),
                  if (data.forecast7Days.isEmpty)
                    Text(
                      'Forecast data is not available at the moment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    SizedBox(
                      height: 126,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.forecast7Days.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final day = data.forecast7Days[index];
                          return SizedBox(
                            width: 62,
                            child: _ForecastChip(
                              day: day.dayLabel,
                              label: _forecastLabel(day.status),
                              category: day.category,
                              active: index == 0,
                            ),
                          );
                        },
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
  const _SummaryCard({required this.data});

  final AirQualityModel data;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(data.aqiStatus);

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
          _SummaryRing(aqi: data.aqi, color: statusColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.aqiStatus.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _summaryTitle(data.aqiStatus),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.insight,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  'Source: Open-Meteo',
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

  String _summaryTitle(String status) {
    if (status == 'Good') {
      return 'Air quality is good.';
    }
    if (status == 'Moderate') {
      return 'Air quality is moderate.';
    }
    return 'Air quality needs attention.';
  }

  Color _statusColor(String status) {
    if (status == 'Good') {
      return AppColors.accent;
    }
    if (status == 'Moderate') {
      return AppColors.moderateAccent;
    }
    if (status == 'Unhealthy for Sensitive Groups') {
      return const Color(0xFFFF6464);
    }
    if (status == 'Unhealthy') {
      return const Color(0xFFFF6464);
    }
    if (status == 'Very Unhealthy') {
      return const Color(0xFFBE63F9);
    }
    return const Color(0xFF8A1C1C);
  }
}

class _SummaryRing extends StatelessWidget {
  const _SummaryRing({required this.aqi, required this.color});

  final int aqi;
  final Color color;

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
            painter: _SummaryRingPainter(
              progress: (aqi / 300).clamp(0, 1),
              color: color,
            ),
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
                color: color,
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
  const _SummaryRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

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
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.35), color],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _SummaryRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
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
                value.toStringAsFixed(1),
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

String _forecastLabel(String status) {
  if (status == 'Good') {
    return 'OK';
  }
  if (status == 'Moderate') {
    return '⚠';
  }
  if (status == 'Unhealthy for Sensitive Groups') {
    return 'USG';
  }
  return 'BAD';
}

class _ForecastChip extends StatelessWidget {
  const _ForecastChip({
    required this.day,
    required this.category,
    required this.label,
    this.active = false,
  });

  final String day;
  final AqiCategory category;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor(category);

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

  Color _dotColor(AqiCategory category) {
    switch (category) {
      case AqiCategory.good:
        return AppColors.accent;
      case AqiCategory.moderate:
        return AppColors.moderateAccent;
      case AqiCategory.unhealthySensitive:
      case AqiCategory.unhealthy:
        return const Color(0xFFFF6464);
      case AqiCategory.veryUnhealthy:
        return const Color(0xFFBE63F9);
      case AqiCategory.hazardous:
        return const Color(0xFF8A1C1C);
    }
  }
}
