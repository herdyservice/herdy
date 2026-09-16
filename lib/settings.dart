import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/date_utils.dart';

/// Date de référence du premier cycle (Jour 1).
final DateTime defaultFirstStart = DateTime(2026, 9, 16);

class AppSettings {
  String name;
  int cycleLength;
  int periodLength;
  DateTime lastStart;

  bool notifPeriod;
  bool notifFertile;
  bool notifMood;
  bool notifSymptom;
  bool notifCustom;
  String customTitle;
  int customHour;
  int customMinute;
  int reminderHour;

  String themeMode; // system | light | dark
  String pinHash;
  bool biometric;
  bool lockEnabled;

  AppSettings({
    required this.name,
    required this.cycleLength,
    required this.periodLength,
    required this.lastStart,
    required this.notifPeriod,
    required this.notifFertile,
    required this.notifMood,
    required this.notifSymptom,
    required this.notifCustom,
    required this.customTitle,
    required this.customHour,
    required this.customMinute,
    required this.reminderHour,
    required this.themeMode,
    required this.pinHash,
    required this.biometric,
    required this.lockEnabled,
  });

  factory AppSettings.defaults() => AppSettings(
        name: 'Ma Sorcière',
        cycleLength: 29,
        periodLength: 5,
        lastStart: defaultFirstStart,
        notifPeriod: true,
        notifFertile: true,
        notifMood: false,
        notifSymptom: false,
        notifCustom: false,
        customTitle: 'Petit rappel 💕',
        customHour: 20,
        customMinute: 0,
        reminderHour: 20,
        themeMode: 'system',
        pinHash: '',
        biometric: false,
        lockEnabled: false,
      );

  ThemeMode get themeModeValue {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copy() => AppSettings.fromJson(toJson());

  Map<String, Object?> toJson() => {
        'name': name,
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'lastStart': iso(lastStart),
        'notifPeriod': notifPeriod,
        'notifFertile': notifFertile,
        'notifMood': notifMood,
        'notifSymptom': notifSymptom,
        'notifCustom': notifCustom,
        'customTitle': customTitle,
        'customHour': customHour,
        'customMinute': customMinute,
        'reminderHour': reminderHour,
        'themeMode': themeMode,
        'pinHash': pinHash,
        'biometric': biometric,
        'lockEnabled': lockEnabled,
      };

  static AppSettings fromJson(Map<String, Object?> j) {
    final d = AppSettings.defaults();
    T pick<T>(String key, T fallback) {
      final v = j[key];
      return v is T ? v : fallback;
    }

    return AppSettings(
      name: pick('name', d.name),
      cycleLength: pick('cycleLength', d.cycleLength),
      periodLength: pick('periodLength', d.periodLength),
      lastStart: j['lastStart'] is String
          ? parseIso(j['lastStart'] as String)
          : d.lastStart,
      notifPeriod: pick('notifPeriod', d.notifPeriod),
      notifFertile: pick('notifFertile', d.notifFertile),
      notifMood: pick('notifMood', d.notifMood),
      notifSymptom: pick('notifSymptom', d.notifSymptom),
      notifCustom: pick('notifCustom', d.notifCustom),
      customTitle: pick('customTitle', d.customTitle),
      customHour: pick('customHour', d.customHour),
      customMinute: pick('customMinute', d.customMinute),
      reminderHour: pick('reminderHour', d.reminderHour),
      themeMode: pick('themeMode', d.themeMode),
      pinHash: pick('pinHash', d.pinHash),
      biometric: pick('biometric', d.biometric),
      lockEnabled: pick('lockEnabled', d.lockEnabled),
    );
  }
}

class SettingsStore {
  static const _prefix = 'ms_';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = AppSettings.defaults();
    return AppSettings(
      name: prefs.getString('${_prefix}name') ?? d.name,
      cycleLength: prefs.getInt('${_prefix}cycleLength') ?? d.cycleLength,
      periodLength: prefs.getInt('${_prefix}periodLength') ?? d.periodLength,
      lastStart: parseIso(
          prefs.getString('${_prefix}lastStart') ?? iso(d.lastStart)),
      notifPeriod: prefs.getBool('${_prefix}notifPeriod') ?? d.notifPeriod,
      notifFertile: prefs.getBool('${_prefix}notifFertile') ?? d.notifFertile,
      notifMood: prefs.getBool('${_prefix}notifMood') ?? d.notifMood,
      notifSymptom: prefs.getBool('${_prefix}notifSymptom') ?? d.notifSymptom,
      notifCustom: prefs.getBool('${_prefix}notifCustom') ?? d.notifCustom,
      customTitle: prefs.getString('${_prefix}customTitle') ?? d.customTitle,
      customHour: prefs.getInt('${_prefix}customHour') ?? d.customHour,
      customMinute: prefs.getInt('${_prefix}customMinute') ?? d.customMinute,
      reminderHour: prefs.getInt('${_prefix}reminderHour') ?? d.reminderHour,
      themeMode: prefs.getString('${_prefix}themeMode') ?? d.themeMode,
      pinHash: prefs.getString('${_prefix}pinHash') ?? d.pinHash,
      biometric: prefs.getBool('${_prefix}biometric') ?? d.biometric,
      lockEnabled: prefs.getBool('${_prefix}lockEnabled') ?? d.lockEnabled,
    );
  }

  static Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}name', s.name);
    await prefs.setInt('${_prefix}cycleLength', s.cycleLength);
    await prefs.setInt('${_prefix}periodLength', s.periodLength);
    await prefs.setString('${_prefix}lastStart', iso(s.lastStart));
    await prefs.setBool('${_prefix}notifPeriod', s.notifPeriod);
    await prefs.setBool('${_prefix}notifFertile', s.notifFertile);
    await prefs.setBool('${_prefix}notifMood', s.notifMood);
    await prefs.setBool('${_prefix}notifSymptom', s.notifSymptom);
    await prefs.setBool('${_prefix}notifCustom', s.notifCustom);
    await prefs.setString('${_prefix}customTitle', s.customTitle);
    await prefs.setInt('${_prefix}customHour', s.customHour);
    await prefs.setInt('${_prefix}customMinute', s.customMinute);
    await prefs.setInt('${_prefix}reminderHour', s.reminderHour);
    await prefs.setString('${_prefix}themeMode', s.themeMode);
    await prefs.setString('${_prefix}pinHash', s.pinHash);
    await prefs.setBool('${_prefix}biometric', s.biometric);
    await prefs.setBool('${_prefix}lockEnabled', s.lockEnabled);
  }
}
