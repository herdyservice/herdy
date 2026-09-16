import 'package:flutter_test/flutter_test.dart';
import 'package:ma_sorciere/core/cycle_engine.dart';
import 'package:ma_sorciere/data/models.dart';
import 'package:ma_sorciere/data/settings.dart';

void main() {
  test('Le 16/09/2026 est bien le Jour 1 du cycle', () {
    final settings = AppSettings.defaults();
    final engine = CycleEngine(
      periods: [PeriodEntry(start: DateTime(2026, 9, 16))],
      settings: settings,
    );
    final info = engine.infoFor(DateTime(2026, 9, 16));
    expect(info.dayOfCycle, 1);
    expect(info.cycleLength, 29);
    expect(info.nextStart, DateTime(2026, 10, 15));
    expect(info.ovulation, DateTime(2026, 10, 1));
  });

  test('La moyenne des cycles est apprise à partir des données', () {
    final engine = CycleEngine(
      periods: [
        PeriodEntry(start: DateTime(2026, 1, 1)),
        PeriodEntry(start: DateTime(2026, 1, 29)), // 28 j
        PeriodEntry(start: DateTime(2026, 2, 28)), // 30 j
      ],
      settings: AppSettings.defaults(),
    );
    expect(engine.averageCycleLength, 29);
    expect(engine.recordedCycles, 2);
  });
}
