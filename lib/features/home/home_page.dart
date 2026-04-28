import 'package:flutter/material.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
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

  static const _city = 'Jakarta';
  static const _aqi = 82;
  static const _status = 'Moderate';
  static const _pm25 = '35';
  static const _uvIndex = '6';
  static const _temperature = '30°';
  static const _dust = 'Low';

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
                  const AqiCard(
                    city: _city,
                    updatedLabel: 'Updated 2 min ago',
                    status: _status,
                    message:
                        'Air quality is decent. Light outdoor activity is okay.',
                    aqi: _aqi,
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(
                    height: 156,
                    child: Row(
                      children: [
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.blur_on,
                            title: 'PM2.5',
                            value: _pm25,
                            subtitle: 'µg/m³',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.wb_sunny_outlined,
                            title: 'UV INDEX',
                            value: _uvIndex,
                            subtitle: 'Moderate',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.thermostat,
                            title: 'TEMP',
                            value: _temperature,
                            subtitle: 'Feels like 32°',
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: AirMetricCard(
                            icon: Icons.grain,
                            title: 'DUST',
                            value: _dust,
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
                          child: const Icon(
                            Icons.check,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Outdoor Activity',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(letterSpacing: 1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Proceed With Caution',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Wear a mask if sensitive and avoid peak traffic hours.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const AiInsightCard(
                    message:
                        'AQI in Jakarta is moderate right now (82). Best time for outdoor activity is before 9 AM or after 6 PM. Keep windows partially closed in high-traffic zones.',
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
