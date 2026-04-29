import 'package:flutter/material.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({
    required this.morningEnabled,
    required this.dangerEnabled,
    required this.onMorningChanged,
    required this.onDangerChanged,
    super.key,
  });

  final bool morningEnabled;
  final bool dangerEnabled;
  final ValueChanged<bool> onMorningChanged;
  final ValueChanged<bool> onDangerChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          _row(
            context,
            icon: Icons.wb_sunny_outlined,
            title: 'Morning report',
            subtitle: 'Daily 7:00 AM summary',
            value: morningEnabled,
            onChanged: onMorningChanged,
          ),
          Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.7),
          ),
          _row(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'Danger alerts',
            subtitle:
                'We\'ll periodically check air quality and notify you when needed.',
            value: dangerEnabled,
            onChanged: onDangerChanged,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
