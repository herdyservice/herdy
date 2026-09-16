import '../data/models.dart';
import '../data/settings.dart';
import 'date_utils.dart';

enum Phase { menstruation, folliculaire, ovulation, luteale }

String phaseLabel(Phase p) {
  switch (p) {
    case Phase.menstruation:
      return 'Règles';
    case Phase.folliculaire:
      return 'Phase folliculaire';
    case Phase.ovulation:
      return 'Ovulation estimée';
    case Phase.luteale:
      return 'Phase lutéale';
  }
}

String phaseEmoji(Phase p) {
  switch (p) {
    case Phase.menstruation:
      return '🔴';
    case Phase.folliculaire:
      return '🌱';
    case Phase.ovulation:
      return '⭐';
    case Phase.luteale:
      return '🌙';
  }
}

class CycleInfo {
  final DateTime date;
  final DateTime cycleStart;
  final DateTime nextStart;
  final DateTime ovulation;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final int dayOfCycle;
  final int cycleLength;
  final Phase phase;
  final bool isPeriod;
  final bool isPeriodRecorded;
  final bool isFertile;
  final bool isOvulation;

  const CycleInfo({
    required this.date,
    required this.cycleStart,
    required this.nextStart,
    required this.ovulation,
    required this.fertileStart,
    required this.fertileEnd,
    required this.dayOfCycle,
    required this.cycleLength,
    required this.phase,
    required this.isPeriod,
    required this.isPeriodRecorded,
    required this.isFertile,
    required this.isOvulation,
  });

  int get daysUntilNext => daysBetween(date, nextStart);
}

class CycleEngine {
  final List<PeriodEntry> periods; // triés par date croissante
  final AppSettings settings;

  CycleEngine({required List<PeriodEntry> periods, required this.settings})
      : periods = List<PeriodEntry>.from(periods)
          ..sort((a, b) => a.start.compareTo(b.start));

  // ---------- Moyennes ----------

  List<int> get cycleLengths {
    final out = <int>[];
    for (var i = 1; i < periods.length; i++) {
      final d = daysBetween(periods[i - 1].start, periods[i].start);
      if (d >= 15 && d <= 60) out.add(d);
    }
    return out;
  }

  List<int> get periodLengths {
    final out = <int>[];
    for (final p in periods) {
      final l = p.length;
      if (l != null && l > 0 && l <= 15) out.add(l);
    }
    return out;
  }

  int get averageCycleLength {
    final l = cycleLengths;
    if (l.isEmpty) return settings.cycleLength;
    final last = l.length > 6 ? l.sublist(l.length - 6) : l;
    final sum = last.fold<int>(0, (a, b) => a + b);
    return (sum / last.length).round();
  }

  double get averagePeriodLengthExact {
    final l = periodLengths;
    if (l.isEmpty) return settings.periodLength.toDouble();
    final sum = l.fold<int>(0, (a, b) => a + b);
    return sum / l.length;
  }

  int get averagePeriodLength {
    final v = averagePeriodLengthExact.round();
    if (v < 1) return 1;
    if (v > 12) return 12;
    return v;
  }

  int get recordedCycles => cycleLengths.length;

  // ---------- Recherche du cycle ----------

  bool hasRecordedStart(DateTime day) {
    for (final p in periods) {
      if (sameDay(p.start, day)) return true;
    }
    return false;
  }

  PeriodEntry? recordedPeriodContaining(DateTime day) {
    for (final p in periods) {
      final end = p.end ?? addDays(p.start, settings.periodLength - 1);
      if (!day.isBefore(p.start) && !day.isAfter(end)) return p;
    }
    return null;
  }

  PeriodEntry? currentOrPreviousPeriod(DateTime day) {
    PeriodEntry? found;
    for (final p in periods) {
      if (!p.start.isAfter(day)) found = p;
    }
    return found;
  }

  PeriodEntry? nextRecordedPeriodAfter(DateTime day) {
    for (final p in periods) {
      if (p.start.isAfter(day)) return p;
    }
    return null;
  }

  /// Début du cycle contenant [date] (enregistré ou projeté).
  DateTime cycleStartFor(DateTime date) {
    final avg = averageCycleLength;
    final previous = currentOrPreviousPeriod(date);
    if (previous != null) {
      var start = previous.start;
      // Si aucun nouveau cycle n'a été enregistré, on projette vers l'avant.
      while (daysBetween(start, date) >= _projectedLengthFrom(start)) {
        start = addDays(start, _projectedLengthFrom(start));
      }
      return start;
    }
    // Aucune donnée antérieure : on projette en arrière depuis la référence.
    final safeAvg = avg < 10 ? 10 : avg;
    var start = periods.isNotEmpty ? periods.first.start : settings.lastStart;
    while (start.isAfter(date)) {
      start = addDays(start, -safeAvg);
    }
    return start;
  }

  int _projectedLengthFrom(DateTime start) {
    final next = nextRecordedPeriodAfter(start);
    if (next != null) {
      final d = daysBetween(start, next.start);
      if (d >= 15 && d <= 60) return d;
    }
    final avg = averageCycleLength;
    return avg < 10 ? 10 : avg;
  }

  bool isPeriodRecordedDay(DateTime day) =>
      recordedPeriodContaining(day) != null;

  bool isPredictedPeriodDay(DateTime day) {
    if (isPeriodRecordedDay(day)) return false;
    final start = cycleStartFor(day);
    if (hasRecordedStart(start)) return false;
    return daysBetween(start, day) < averagePeriodLength;
  }

  // ---------- Information complète ----------

  CycleInfo infoFor(DateTime raw) {
    final date = dOnly(raw);
    final start = cycleStartFor(date);
    final length = _projectedLengthFrom(start);
    final next = addDays(start, length);
    final ovulation = addDays(next, -14);
    final fertileStart = addDays(ovulation, -5);
    final fertileEnd = addDays(ovulation, 1);

    final recorded = isPeriodRecordedDay(date);
    final isPeriod = recorded || isPredictedPeriodDay(date);
    final isOvu = sameDay(ovulation, date);
    final isFertile =
        !date.isBefore(fertileStart) && !date.isAfter(fertileEnd);

    Phase phase;
    if (isPeriod) {
      phase = Phase.menstruation;
    } else if (isOvu) {
      phase = Phase.ovulation;
    } else if (date.isBefore(ovulation)) {
      phase = Phase.folliculaire;
    } else {
      phase = Phase.luteale;
    }

    return CycleInfo(
      date: date,
      cycleStart: start,
      nextStart: next,
      ovulation: ovulation,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      dayOfCycle: daysBetween(start, date) + 1,
      cycleLength: length,
      phase: phase,
      isPeriod: isPeriod,
      isPeriodRecorded: recorded,
      isFertile: isFertile,
      isOvulation: isOvu,
    );
  }

  /// Historique : [début, durée] pour chaque cycle terminé.
  List<MapEntry<DateTime, int>> get history {
    final out = <MapEntry<DateTime, int>>[];
    for (var i = 1; i < periods.length; i++) {
      out.add(MapEntry(
          periods[i - 1].start, daysBetween(periods[i - 1].start, periods[i].start)));
    }
    return out;
  }
}
