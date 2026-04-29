import 'dart:async';

import 'package:flutter/material.dart';

import '../data/local_notification_service.dart';
import '../domain/notification_payload.dart';

class NotificationPopupHandler extends StatefulWidget {
  const NotificationPopupHandler({required this.child, super.key});

  final Widget child;

  @override
  State<NotificationPopupHandler> createState() => _NotificationPopupHandlerState();
}

class _NotificationPopupHandlerState extends State<NotificationPopupHandler> {
  StreamSubscription<NotificationPayload>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = LocalNotificationService.instance.onNotificationTap.listen(
      _showPayloadDialog,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = LocalNotificationService.instance.takeLaunchPayload();
      if (payload != null) {
        _showPayloadDialog(payload);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showPayloadDialog(NotificationPayload payload) {
    if (!mounted) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final title = payload.type == AirNotificationType.morningReport
            ? 'Morning Report'
            : 'Danger Alert';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(payload.locationLabel),
              const SizedBox(height: 6),
              Text('AQI ${payload.aqi} · ${payload.status}'),
              const SizedBox(height: 6),
              Text('PM2.5 ${payload.pm25.toStringAsFixed(0)} · PM10 ${payload.pm10.toStringAsFixed(0)}'),
              const SizedBox(height: 10),
              Text(payload.message),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
