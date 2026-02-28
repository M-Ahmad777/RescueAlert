import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

const _channelId = 'rescue_alert_foreground';
const _notifId = 888;

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const channel = AndroidNotificationChannel(
    _channelId,
    'RescueAlert - SOS Active',
    description: 'Foreground service for live location sharing during SOS',
    importance: Importance.high,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _channelId,
      initialNotificationTitle: '🚨 RescueAlert SOS Active',
      initialNotificationContent: 'Sharing your live location...',
      foregroundServiceNotificationId: _notifId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onStart,
      onBackground: _onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!await service.isForegroundService()) {
        timer.cancel();
        return;
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );

        plugin.show(
          _notifId,
          '🚨 RescueAlert SOS Active',
          'Location: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'RescueAlert - SOS Active',
              icon: '@mipmap/ic_launcher',
              ongoing: true,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );

        service.invoke('locationUpdate', {
          'lat': pos.latitude,
          'lng': pos.longitude,
        });
      } catch (_) {}
    }
  });

  service.on('stopService').listen((_) => service.stopSelf());
}

void startForegroundService() => FlutterBackgroundService().startService();
void stopForegroundService() => FlutterBackgroundService().invoke('stopService');