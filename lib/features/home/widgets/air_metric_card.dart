import 'package:flutter/material.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class AirMetricCard extends StatelessWidget {
  const AirMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accentStrong, size: 20),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 30,
                color: AppColors.textPrimary,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textPrimary.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 1),
          SizedBox(
            height: 14,
            child: subtitle == null
                ? const SizedBox.shrink()
                : Text(
                    subtitle!,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 10, height: 1.1),
                  ),
          ),
        ],
      ),
    );
  }
}
