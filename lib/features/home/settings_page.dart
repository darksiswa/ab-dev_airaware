import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/ads/banner_ad_widget.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../notifications/presentation/notification_settings_controller.dart';
import '../settings/domain/health_config.dart';
import '../settings/presentation/health_config_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthConfigController>();
    final config = health.config;
    final notification = context.watch<NotificationSettingsController>();
    final notifSettings = notification.settings;

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
                                color: AppColors.accentStrong,
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
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'In-app purchase flow (demo UI only).',
                                  ),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentSoft,
                              foregroundColor: AppColors.accentStrong,
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 16,
                              ),
                              visualDensity: VisualDensity.standard,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Upgrade for Rp49.000/month',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.accentStrong,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          height: 1.1,
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
                  const SizedBox(height: 12),
                  Text(
                    'Sponsored · Ad',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: BannerAdWidget()),
                  const SizedBox(height: 14),
                  _sectionTitle(context, 'NOTIFICATIONS'),
                  const SizedBox(height: 6),
                  _SettingsGroup(
                    children: [
                      _SwitchRow(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Morning report',
                        subtitle: 'Daily 7:00 AM summary',
                        value: notifSettings.morningReportEnabled,
                        onChanged: (v) =>
                            notification.setMorningReportEnabled(v),
                      ),
                      _SwitchRow(
                        icon: Icons.warning_amber_rounded,
                        title: 'Danger alerts',
                        subtitle:
                            'We’ll periodically check air quality and notify you when needed.',
                        value: notifSettings.dangerAlertEnabled,
                        onChanged: (v) => _onDangerAlertChanged(
                          context,
                          controller: notification,
                          enabled: v,
                        ),
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
                              active:
                                  config.temperatureUnit ==
                                  TemperatureUnit.celsius,
                              onTap: () => health.setTemperatureUnit(
                                TemperatureUnit.celsius,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ChoiceChip(
                              label: '°F',
                              active:
                                  config.temperatureUnit ==
                                  TemperatureUnit.fahrenheit,
                              onTap: () => health.setTemperatureUnit(
                                TemperatureUnit.fahrenheit,
                              ),
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
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary.withValues(alpha: 0.9),
      ),
    );
  }

  Future<void> _onDangerAlertChanged(
    BuildContext context, {
    required NotificationSettingsController controller,
    required bool enabled,
  }) async {
    if (!enabled) {
      await controller.setDangerAlertEnabled(false);
      return;
    }

    if (!context.mounted) {
      return;
    }
    final askPermission = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'AirAware needs notification permission to send air quality alerts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Allow Notifications'),
            ),
          ],
        );
      },
    );

    if (askPermission != true) {
      await controller.setDangerAlertEnabled(false);
      return;
    }

    final permissionResult = await controller.requestNotificationPermission();
    if (permissionResult != NotificationPermissionResult.granted) {
      if (!context.mounted) {
        return;
      }
      await controller.setDangerAlertEnabled(false);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerts need notification permission to work.'),
        ),
      );
      return;
    }

    await controller.setDangerAlertEnabled(true);

    final batteryOptimizationEnabled = await controller
        .isBatteryOptimizationEnabled();
    if (!context.mounted) {
      return;
    }
    if (batteryOptimizationEnabled == true) {
      final openBatterySettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Keep danger alerts working'),
            content: const Text(
              'Android may delay background checks when battery optimization is enabled. To receive more reliable air quality alerts, allow AirAware to run in the background.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not Now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Open Battery Settings'),
              ),
            ],
          );
        },
      );

      if (openBatterySettings == true) {
        await controller.openBatteryOptimizationSettings();
      }
    }
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
            child: Icon(icon, color: AppColors.accentStrong),
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
                ? AppColors.accentStrong.withValues(alpha: 0.72)
                : AppColors.textSecondary.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: active ? AppColors.accentStrong : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
