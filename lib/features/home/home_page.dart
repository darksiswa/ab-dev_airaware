import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../air_quality/domain/air_quality_model.dart';
import '../air_quality/domain/air_precaution_generator.dart';
import '../air_quality/presentation/air_quality_controller.dart';
import '../settings/domain/health_config.dart';
import '../settings/presentation/health_config_controller.dart';
import 'detail_page.dart';
import 'settings_page.dart';
import 'tips_page.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/air_metric_card.dart';
import 'widgets/aqi_card.dart';

const bool _showDebugPanel =
    kDebugMode && bool.fromEnvironment('SHOW_DEBUG_UI', defaultValue: false);

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
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.5,
            colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.backgroundLift,
              AppColors.background,
            ],
            stops: const [0, 0.48, 1],
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
  static const _precautionGenerator = AirPrecautionGenerator();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AirQualityController>();
    final healthConfig = context.watch<HealthConfigController>().config;

    if (controller.isInitialLoading && controller.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accentStrong),
            const SizedBox(height: 12),
            Text(
              controller.locationStatusText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
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
    final precaution = _precautionGenerator.generate(
      data: data,
      config: healthConfig,
    );

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
                  Row(
                    children: [
                      const Spacer(),
                      if (controller.shouldShowRetryLocation)
                        TextButton(
                          onPressed: () async {
                            await context
                                .read<AirQualityController>()
                                .retryLocation();
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
                          child: const Text('Re-check Location'),
                        ),
                    ],
                  ),
                  if (controller.isRefreshing) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentStrong,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Refreshing...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  if (_showDebugPanel) _DebugPanel(controller: controller),
                  if (controller.infoMessage != null &&
                      (_showDebugPanel ||
                          !_isDebugOnlyInfoMessage(
                            controller.infoMessage!,
                          ))) ...[
                    const SizedBox(height: 4),
                    Text(
                      controller.infoMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  AqiCard(
                    city: data.cityLabel,
                    updatedLabel: controller.lastUpdatedRelativeText,
                    status: _statusBadge(data.aqiStatus),
                    message: _statusMessage(data),
                    aqi: data.aqi,
                    onRefresh: () async {
                      await context
                          .read<AirQualityController>()
                          .manualRefresh();
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
                            value: _temperatureLabel(
                              data.temperature,
                              healthConfig.temperatureUnit,
                            ),
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
                    icon: const Icon(Icons.arrow_forward_rounded),
                    iconAlignment: IconAlignment.end,
                    label: const Text('View Full Detail'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentSoft,
                      foregroundColor: AppColors.accentStrong,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      side: const BorderSide(color: AppColors.borderStrong),
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
                          child: const Icon(
                            Icons.air,
                            color: AppColors.accentStrong,
                          ),
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
                  AiInsightCard(
                    title: precaution.title,
                    message: precaution.message,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  String _temperatureLabel(double celsius, TemperatureUnit unit) {
    if (unit == TemperatureUnit.fahrenheit) {
      final f = (celsius * 9 / 5) + 32;
      return '${f.toStringAsFixed(0)}°F';
    }
    return '${celsius.toStringAsFixed(0)}°C';
  }

  bool _isDebugOnlyInfoMessage(String message) {
    return message == 'Showing cached data from the last update.' ||
        message == 'Area changed. Updating air quality data…';
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.controller});

  final AirQualityController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: () async {
            await context
                .read<AirQualityController>()
                .forceRecheckDeviceLocation();
          },
          child: const Text('Force Re-check Device Location'),
        ),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Debug Location Override',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Use this only when emulator location provider fails.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<AirQualityController>()
                          .applyDebugLocationOverride(
                            label: 'Dubai',
                            latitude: 25.2048,
                            longitude: 55.2708,
                          );
                    },
                    child: const Text('Dubai'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<AirQualityController>()
                          .applyDebugLocationOverride(
                            label: 'Jakarta',
                            latitude: -6.2088,
                            longitude: 106.8456,
                          );
                    },
                    child: const Text('Jakarta'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<AirQualityController>()
                          .applyDebugLocationOverride(
                            label: 'Bandung',
                            latitude: -6.9175,
                            longitude: 107.6191,
                          );
                    },
                    child: const Text('Bandung'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<AirQualityController>()
                          .applyDebugLocationOverride(
                            label: 'Seoul',
                            latitude: 37.5665,
                            longitude: 126.9780,
                          );
                    },
                    child: const Text('Seoul'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        AppCard(
          child: Text(
            [
              'DBG source=${controller.debugLocationSource ?? '-'}',
              'DBG cacheKey=${controller.debugCacheKey ?? '-'}',
              'DBG cacheReused=${controller.debugCacheReused?.toString() ?? '-'}',
              'DBG apiFetched=${controller.debugApiFetched?.toString() ?? '-'}',
            ].join('\n'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
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
        color: AppColors.surface.withValues(alpha: 0.78),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
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
    final color = active ? AppColors.accentStrong : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: active ? AppColors.accentSoft : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 23),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: active ? 14 : 6,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: active ? AppColors.accentStrong : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
