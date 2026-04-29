import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../settings/presentation/health_config_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool morningReport = true;
  bool dangerAlerts = true;
  String tempUnit = '°C';

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthConfigController>();
    final config = health.config;

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
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle(context, 'IN-APP PURCHASE'),
                  const SizedBox(height: 6),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: AppColors.accentSoft,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AirAware Pro',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Unlock advanced alerts and AI daily forecast',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'In-app purchase flow (demo UI only).',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Upgrade for Rp49.000/month'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentSoft,
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle(context, 'NOTIFICATIONS'),
                  const SizedBox(height: 6),
                  _SettingsGroup(
                    children: [
                      _SwitchRow(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Morning report',
                        subtitle: 'Daily 7:00 AM summary',
                        value: morningReport,
                        onChanged: (v) => setState(() => morningReport = v),
                      ),
                      _SwitchRow(
                        icon: Icons.warning_amber_rounded,
                        title: 'Danger alerts',
                        subtitle: 'Notify when AQI > 150',
                        value: dangerAlerts,
                        onChanged: (v) => setState(() => dangerAlerts = v),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle(context, 'HEALTH PROFILE'),
                  const SizedBox(height: 6),
                  _SettingsGroup(
                    children: [
                      _SwitchRow(
                        icon: Icons.air,
                        title: 'Asthma Mode',
                        subtitle:
                            'Show stronger breathing precautions when air quality may affect asthma.',
                        value: config.asthmaMode,
                        onChanged: (v) => health.setAsthmaMode(v),
                      ),
                      _SwitchRow(
                        icon: Icons.masks_rounded,
                        title: 'Allergy Mode',
                        subtitle:
                            'Show allergy-focused warnings for dust, PM10, and pollen when available.',
                        value: config.allergyMode,
                        onChanged: (v) => health.setAllergyMode(v),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle(context, 'DISPLAY'),
                  const SizedBox(height: 6),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temperature unit',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _ChoiceChip(
                              label: '°C',
                              active: tempUnit == '°C',
                              onTap: () => setState(() => tempUnit = '°C'),
                            ),
                            const SizedBox(width: 8),
                            _ChoiceChip(
                              label: '°F',
                              active: tempUnit == '°F',
                              onTap: () => setState(() => tempUnit = '°F'),
                            ),
                          ],
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

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        letterSpacing: 2.8,
        color: AppColors.textSecondary.withValues(alpha: 0.9),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.accentSoft,
            ),
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? AppColors.accentSoft : Colors.transparent,
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.75)
                : AppColors.textSecondary.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: active ? AppColors.accent : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
