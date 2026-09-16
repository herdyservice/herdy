import 'package:flutter/foundation.dart';

import '../core/cycle_engine.dart';
import '../core/date_utils.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../data/settings.dart';
import '../services/notification_service.dart';

final AppState appState = AppState();

class AppState extends ChangeNotifier {
  AppSettings settings = AppSettings.defaults();
  List<PeriodEntry> periods = <PeriodEntry>[];
  Map<String, MoodEntry> moods = <String, MoodEntry>{};
  Map<String, List<SymptomEntry>> symptoms = <String, List<SymptomEntry>>{};
  Map<String, List<IntercourseEntry>> intercourse =
      <String, List<IntercourseEntry>>{};

  bool loading = true;
  bool unlocked = false;

  CycleEngine get engine =>
      CycleEngine(periods: periods, settings: settings);

  CycleInfo get todayInfo => engine.infoFor(DateTime.now());

  MoodEntry? moodOn(DateTime d) => moods[iso(d)];
  List<SymptomEntry> symptomsOn(DateTime d) =>
      symptoms[iso(d)] ?? <SymptomEntry>[];
  List<IntercourseEntry> intercourseOn(DateTime d) =>
      intercourse[iso(d)] ?? <IntercourseEntry>[];

  List<SymptomEntry> get allSymptoms =>
      symptoms.values.expand((e) => e).toList();
  List<MoodEntry> get allMoods => moods.values.toList();
  List<IntercourseEntry> get allIntercourse =>
      intercourse.values.expand((e) => e).toList();

  Future<void> load() async {
    settings = await SettingsStore.load();
    await _reload();
    // Amorçage : le premier cycle de référence est enregistré automatiquement.
    if (periods.isEmpty) {
      await AppDatabase.instance
          .upsertPeriod(PeriodEntry(start: dOnly(settings.lastStart)));
      await _reload();
    }
    loading = false;
    unlocked = !settings.lockEnabled;
    notifyListeners();
    await refreshNotifications();
  }

  Future<void> _reload() async {
    final db = AppDatabase.instance;
    periods = await db.getPeriods();

    final m = <String, MoodEntry>{};
    for (final e in await db.getMoods()) {
      m[iso(e.date)] = e;
    }
    moods = m;

    final s = <String, List<SymptomEntry>>{};
    for (final e in await db.getSymptoms()) {
      s.putIfAbsent(iso(e.date), () => <SymptomEntry>[]).add(e);
    }
    symptoms = s;

    final i = <String, List<IntercourseEntry>>{};
    for (final e in await db.getIntercourse()) {
      i.putIfAbsent(iso(e.date), () => <IntercourseEntry>[]).add(e);
    }
    intercourse = i;
  }

  Future<void> refresh() async {
    await _reload();
    notifyListeners();
    await refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    try {
      await NotificationService.reschedule(settings, todayInfo);
    } catch (_) {
      // Les notifications ne doivent jamais bloquer l'application.
    }
  }

  void unlock() {
    unlocked = true;
    notifyListeners();
  }

  // ---------- Écritures ----------

  Future<void> saveSettings(AppSettings s) async {
    settings = s;
    await SettingsStore.save(s);
    notifyListeners();
    await refreshNotifications();
  }

  Future<void> savePeriod(PeriodEntry e) async {
    await AppDatabase.instance.upsertPeriod(e);
    final latest = periods.isEmpty ? e.start : periods.last.start;
    if (!e.start.isBefore(latest)) {
      settings.lastStart = dOnly(e.start);
      await SettingsStore.save(settings);
    }
    await refresh();
  }

  Future<void> deletePeriod(int id) async {
    await AppDatabase.instance.deletePeriod(id);
    await refresh();
  }

  /// Marque (ou retire) le début des règles sur une date donnée.
  Future<void> togglePeriodStart(DateTime date) async {
    final day = dOnly(date);
    PeriodEntry? existing;
    for (final p in periods) {
      if (sameDay(p.start, day)) existing = p;
    }
    if (existing != null) {
      await deletePeriod(existing.id!);
    } else {
      await savePeriod(PeriodEntry(start: day));
    }
  }

  Future<void> setPeriodEnd(DateTime date) async {
    final day = dOnly(date);
    PeriodEntry? target;
    for (final p in periods) {
      if (!p.start.isAfter(day)) target = p;
    }
    if (target == null) return;
    await savePeriod(target.copyWith(end: day));
  }

  Future<void> saveMood(MoodEntry e) async {
    await AppDatabase.instance.saveMood(e);
    await refresh();
  }

  Future<void> saveSymptoms(DateTime date, List<SymptomEntry> list) async {
    await AppDatabase.instance.saveSymptoms(dOnly(date), list);
    await refresh();
  }

  Future<void> saveIntercourse(IntercourseEntry e) async {
    await AppDatabase.instance.saveIntercourse(e);
    await refresh();
  }

  Future<void> deleteIntercourse(int id) async {
    await AppDatabase.instance.deleteIntercourse(id);
    await refresh();
  }

  Future<void> eraseEverything() async {
    await AppDatabase.instance.clearAll();
    settings = AppSettings.defaults();
    await SettingsStore.save(settings);
    await NotificationService.cancelAll();
    await AppDatabase.instance
        .upsertPeriod(PeriodEntry(start: dOnly(settings.lastStart)));
    await refresh();
  }

  Future<void> applyImportedSettings(AppSettings s) async {
    settings = s;
    await refresh();
  }
}
