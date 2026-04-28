import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../air_quality/domain/air_quality_model.dart';
import '../air_quality/presentation/air_quality_controller.dart';
import 'detail_page.dart';
import 'settings_page.dart';
import 'tips_page.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/air_metric_card.dart';
import 'widgets/aqi_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _goToDetail() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(onOpenDetail: _goToDetail),
      const DetailPage(),
      const TipsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.5,
            colors: [Color(0xFF11483F), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: pages),
              ),
              _BottomNav(
                selectedIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onOpenDetail});

  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AirQualityController>();

    if (controller.isLoading && controller.data == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (controller.state == AirQualityViewState.error &&
        controller.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load air quality data.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage ?? 'Please try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      context.read<AirQualityController>().initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = controller.data;
    if (data == null) {
      return const SizedBox.shrink();
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
                  AqiCard(
                    city: data.cityLabel,
                    updatedLabel:
                        'Updated ${_formatLastUpdated(controller.lastUpdatedAt)}',
                    status: _statusBadge(data.aqiStatus),
                    message: _statusMessage(data),
                    aqi: data.aqi,
                    onRefresh: () async {
                      await context.read<AirQualityController>().manualRefresh();
                      if (!context.mounted) {
                        return;
                      }
                      final message = context
                          .read<AirQualityController>()
                          .infoMessage;
                      if (message != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 156,
                    child: Row(
                      children: [
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.blur_on,
                            title: 'PM2.5',
                            value: data.pm25Label,
                            subtitle: 'µg/m³',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.grain,
                            title: 'UV INDEX',
                            value: data.uvIndexLabel,
                            subtitle: data.uvIndex <= 2
                                ? 'Low'
                                : data.uvIndex <= 5
                                ? 'Moderate'
                                : data.uvIndex <= 7
                                ? 'High'
                                : 'Very High',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.thermostat,
                            title: 'TEMP',
                            value: data.temperatureLabel,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.water_drop,
                            title: 'HUMIDITY',
                            value: data.humidityLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onOpenDetail,
                    icon: const Text('View Full Detail'),
                    iconAlignment: IconAlignment.end,
                    label: const Icon(Icons.arrow_forward),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentSoft,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 18,
                      ),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.accentSoft,
                          ),
                          child: const Icon(Icons.air, color: AppColors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.aqiStatus,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Wind speed: ${data.windSpeedLabel}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AiInsightCard(message: data.insight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatLastUpdated(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _statusBadge(String fullStatus) {
    if (fullStatus == 'Unhealthy for Sensitive Groups') {
      return 'Sensitive';
    }
    return fullStatus;
  }

  String _statusMessage(AirQualityModel data) {
    return data.aqiStatus == 'Good'
        ? 'Great day to be outside.'
        : data.aqiStatus == 'Moderate'
        ? 'Air quality is moderate. Take precautions if you are sensitive.'
        : 'Air quality is unhealthy. Limit prolonged outdoor activity.';
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface.withValues(alpha: 0.45),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            active: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.timelapse_outlined,
            label: 'Detail',
            active: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.task_alt_outlined,
            label: 'Tips',
            active: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            active: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.accent : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
