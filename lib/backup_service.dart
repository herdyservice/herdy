import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/date_utils.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../data/settings.dart';

class BackupResult {
  final String json;
  final String? path;
  const BackupResult(this.json, this.path);
}

class BackupService {
  static Future<BackupResult> export(AppSettings settings) async {
    final db = AppDatabase.instance;
    final data = <String, Object?>{
      'app': 'ma_sorciere',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'periods': (await db.getPeriods()).map((e) => e.toMap()).toList(),
      'moods': (await db.getMoods()).map((e) => e.toMap()).toList(),
      'symptoms': (await db.getSymptoms()).map((e) => e.toMap()).toList(),
      'intercourse': (await db.getIntercourse()).map((e) => e.toMap()).toList(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(data);

    String? path;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(
          dir.path, 'ma-sorciere-sauvegarde-${iso(DateTime.now())}.json'));
      await file.writeAsString(json);
      path = file.path;
    } catch (_) {
      path = null;
    }
    return BackupResult(json, path);
  }

  /// Retourne les paramètres importés. Lève une exception si le contenu est invalide.
  static Future<AppSettings> import(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Fichier de sauvegarde invalide.');
    }
    final map = decoded.cast<String, Object?>();
    if (map['app'] != 'ma_sorciere') {
      throw const FormatException(
          'Ce fichier ne provient pas de Ma Sorcière ❤️.');
    }

    List<Map<String, Object?>> rows(String key) {
      final v = map[key];
      if (v is! List) return <Map<String, Object?>>[];
      return v
          .whereType<Map>()
          .map((e) => e.cast<String, Object?>())
          .toList();
    }

    await AppDatabase.instance.importAll(
      periods: rows('periods').map(PeriodEntry.fromMap).toList(),
      moods: rows('moods').map(MoodEntry.fromMap).toList(),
      symptoms: rows('symptoms').map(SymptomEntry.fromMap).toList(),
      intercourse: rows('intercourse').map(IntercourseEntry.fromMap).toList(),
    );

    final s = map['settings'];
    final settings = s is Map
        ? AppSettings.fromJson(s.cast<String, Object?>())
        : AppSettings.defaults();
    await SettingsStore.save(settings);
    return settings;
  }
}
