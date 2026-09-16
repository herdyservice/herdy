import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final engine = appState.engine;
        final history = engine.history;
        final scheme = Theme.of(context).colorScheme;

        final symptomCounts = <String, int>{};
        for (final s in appState.allSymptoms) {
          symptomCounts[s.name] = (symptomCounts[s.name] ?? 0) + 1;
        }
        final symptomFreq = symptomCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final moodCounts = <String, int>{};
        for (final m in appState.allMoods) {
          for (final id in m.moods) {
            moodCounts[id] = (moodCounts[id] ?? 0) + 1;
          }
        }
        final moodFreq = moodCounts.entries
            .map((e) => MapEntry(
                '${moodById(e.key).emoji} ${moodById(e.key).label}', e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final chartData = history.length > 8
            ? history.sublist(history.length - 8)
            : history;

        return Scaffold(
          appBar: AppBar(title: const Text('Statistiques 📊')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '${engine.averageCycleLength}',
                      unit: 'jours',
                      label: 'Cycle moyen',
                      color: AppTheme.rose,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      value: engine.averagePeriodLengthExact
                          .toStringAsFixed(1),
                      unit: 'jours',
                      label: 'Règles moyennes',
                      color: AppTheme.lavande,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '${engine.recordedCycles}',
                      unit: '',
                      label: 'Cycles complets',
                      color: AppTheme.vert,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      value: '${appState.periods.length}',
                      unit: '',
                      label: 'Périodes notées',
                      color: AppTheme.or,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Évolution de la durée du cycle',
                child: chartData.isEmpty
                    ? const EmptyHint(
                        'Il faut au moins deux cycles enregistrés pour afficher le graphique.')
                    : SimpleBarChart(
                        values:
                            chartData.map((e) => e.value.toDouble()).toList(),
                        labels: chartData
                            .map((e) =>
                                '${e.key.day}/${moisCourtFr[e.key.month - 1]}')
                            .toList(),
                        color: scheme.primary,
                      ),
              ),
              SectionCard(
                title: 'Symptômes les plus fréquents',
                child: FrequencyBars(
                  data: symptomFreq.take(6).toList(),
                  color: AppTheme.lavande,
                ),
              ),
              SectionCard(
                title: 'Humeurs les plus fréquentes',
                child: FrequencyBars(
                  data: moodFreq.take(6).toList(),
                  color: AppTheme.rose,
                ),
              ),
              SectionCard(
                title: 'Historique des cycles',
                child: history.isEmpty
                    ? const EmptyHint('Pas encore de cycle complet.')
                    : Column(
                        children: history.reversed
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Début ${fmtCourt(e.key)}'),
                                      Text('${e.value} jours',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ),
              const NoticeBox(text: disclaimerMedical),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _StatBox({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700, color: color),
          ),
          if (unit.isNotEmpty)
            Text(unit, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
