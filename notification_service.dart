import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/cycle_engine.dart';
import '../core/date_utils.dart';
import '../data/settings.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'ma_sorciere_channel',
    'Ma Sorcière',
    channelDescription: 'Rappels du cycle, humeurs et symptômes',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _android);

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      _setLocalLocation();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: android),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Détermine le fuseau local sans dépendance supplémentaire :
  /// on cherche une zone dont le décalage correspond à celui de l'appareil.
  static void _setLocalLocation() {
    final offset = DateTime.now().timeZoneOffset;
    for (final location in tz.timeZoneDatabase.locations.values) {
      final now = tz.TZDateTime.now(location);
      if (now.timeZoneOffset == offset) {
        tz.setLocalLocation(location);
        return;
      }
    }
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  static Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  static Future<void> reschedule(AppSettings s, CycleInfo info) async {
    if (!_ready) return;
    await _plugin.cancelAll();

    if (s.notifPeriod) {
      await _oneShot(
        1,
        'Ma Sorcière ❤️',
        'Tes règles sont estimées pour demain 🌸 Prends soin de toi.',
        addDays(info.nextStart, -1),
        9,
        0,
      );
      await _oneShot(
        2,
        'Ma Sorcière ❤️',
        'Jour 1 estimé de ton cycle aujourd\u2019hui. Pense à l\u2019enregistrer.',
        info.nextStart,
        9,
        0,
      );
    }

    if (s.notifFertile) {
      await _oneShot(
        3,
        'Ma Sorcière ❤️',
        'La fenêtre fertile estimée commence demain. Ce n\u2019est qu\u2019une estimation.',
        addDays(info.fertileStart, -1),
        9,
        0,
      );
    }

    if (s.notifMood) {
      await _daily(
        4,
        'Ma Sorcière ❤️',
        'Comment te sens-tu aujourd\u2019hui ? 😊',
        s.reminderHour,
        0,
      );
    }

    if (s.notifSymptom) {
      await _daily(
        5,
        'Ma Sorcière ❤️',
        'As-tu des symptômes à noter aujourd\u2019hui ?',
        s.reminderHour,
        30,
      );
    }

    if (s.notifCustom) {
      await _daily(6, 'Ma Sorcière ❤️', s.customTitle, s.customHour,
          s.customMinute);
    }
  }

  static Future<void> _oneShot(int id, String title, String body, DateTime day,
      int hour, int minute) async {
    final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> _daily(
      int id, String title, String body, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
