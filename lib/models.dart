import "date_utils.dart";
import '../core/date_utils.dart';

class PeriodEntry {
  final int? id;
  final DateTime start;
  final DateTime? end;
  final String flow; // legere | moyenne | forte
  final int pain; // 0..3
  final String notes;

  PeriodEntry({
    this.id,
    required this.start,
    this.end,
    this.flow = 'moyenne',
    this.pain = 0,
    this.notes = '',
  });

  int? get length => end == null ? null : daysBetween(start, end!) + 1;

  PeriodEntry copyWith({
    int? id,
    DateTime? start,
    DateTime? end,
    bool clearEnd = false,
    String? flow,
    int? pain,
    String? notes,
  }) {
    return PeriodEntry(
      id: id ?? this.id,
      start: start ?? this.start,
      end: clearEnd ? null : (end ?? this.end),
      flow: flow ?? this.flow,
      pain: pain ?? this.pain,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'start_date': iso(start),
        'end_date': end == null ? null : iso(end!),
        'flow': flow,
        'pain': pain,
        'notes': notes,
      };

  static PeriodEntry fromMap(Map<String, Object?> m) => PeriodEntry(
        id: m['id'] as int?,
        start: parseIso(m['start_date'] as String),
        end: m['end_date'] == null ? null : parseIso(m['end_date'] as String),
        flow: (m['flow'] as String?) ?? 'moyenne',
        pain: (m['pain'] as int?) ?? 0,
        notes: (m['notes'] as String?) ?? '',
      );
}

class MoodEntry {
  final int? id;
  final DateTime date;
  final List<String> moods;
  final String note;

  MoodEntry({this.id, required this.date, required this.moods, this.note = ''});

  Map<String, Object?> toMap() => {
        'id': id,
        'date': iso(date),
        'moods': moods.join(','),
        'note': note,
      };

  static MoodEntry fromMap(Map<String, Object?> m) {
    final raw = (m['moods'] as String?) ?? '';
    return MoodEntry(
      id: m['id'] as int?,
      date: parseIso(m['date'] as String),
      moods: raw.isEmpty ? <String>[] : raw.split(','),
      note: (m['note'] as String?) ?? '',
    );
  }
}

class SymptomEntry {
  final int? id;
  final DateTime date;
  final String name;
  final int intensity; // 1..3

  SymptomEntry({
    this.id,
    required this.date,
    required this.name,
    required this.intensity,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'date': iso(date),
        'name': name,
        'intensity': intensity,
      };

  static SymptomEntry fromMap(Map<String, Object?> m) => SymptomEntry(
        id: m['id'] as int?,
        date: parseIso(m['date'] as String),
        name: m['name'] as String,
        intensity: (m['intensity'] as int?) ?? 1,
      );
}

class IntercourseEntry {
  final int? id;
  final DateTime date;
  final String? time; // "HH:mm"
  final bool protectedSex;
  final bool condom;
  final bool contraception;
  final String notes;

  IntercourseEntry({
    this.id,
    required this.date,
    this.time,
    this.protectedSex = false,
    this.condom = false,
    this.contraception = false,
    this.notes = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'date': iso(date),
        'time': time,
        'protected_sex': protectedSex ? 1 : 0,
        'condom': condom ? 1 : 0,
        'contraception': contraception ? 1 : 0,
        'notes': notes,
      };

  static IntercourseEntry fromMap(Map<String, Object?> m) => IntercourseEntry(
        id: m['id'] as int?,
        date: parseIso(m['date'] as String),
        time: m['time'] as String?,
        protectedSex: ((m['protected_sex'] as int?) ?? 0) == 1,
        condom: ((m['condom'] as int?) ?? 0) == 1,
        contraception: ((m['contraception'] as int?) ?? 0) == 1,
        notes: (m['notes'] as String?) ?? '',
      );
}
