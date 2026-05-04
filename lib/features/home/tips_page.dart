import 'package:flutter/material.dart';

import '../../shared/ads/native_ad_widget.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TipsHeader(),
                  SizedBox(height: 14),
                  _TipCard(
                    icon: Icons.directions_run,
                    title: 'Ideal for outdoor exercise',
                    body:
                        'AQI is moderate. Prefer lighter activities and avoid peak traffic hours.',
                  ),
                  SizedBox(height: 10),
                  _TipCard(
                    icon: Icons.wb_sunny,
                    title: 'UV is moderate',
                    body:
                        'Apply SPF 30+ if you plan to be outdoors more than 30 minutes.',
                  ),
                  SizedBox(height: 10),
                  NativeAdWidget(
                    fallback: _SponsoredBar(),
                  ),
                  SizedBox(height: 10),
                  _TipCard(
                    icon: Icons.water_drop,
                    title: 'Stay hydrated',
                    body:
                        'Even on moderate AQI days, drink 2L+ of water if exercising.',
                  ),
                  SizedBox(height: 10),
                  _TipCard(
                    icon: Icons.eco,
                    title: 'Ventilate wisely',
                    body:
                        'Open windows early morning when traffic is lower, then close at rush hour.',
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

class _TipsHeader extends StatelessWidget {
  const _TipsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on current conditions in your area',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSoft,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Icon(icon, color: AppColors.accentStrong, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 17,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentStrong,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.accentStrong,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _SponsoredBar extends StatelessWidget {
  const _SponsoredBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
          style: BorderStyle.solid,
        ),
        color: AppColors.surface.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          Text(
            'SPONSORED',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Ad',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.accentStrong),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.accentStrong),
        ],
      ),
    );
  }
}
