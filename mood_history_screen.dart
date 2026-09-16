import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final entries = appState.allMoods
          ..sort((a, b) => b.date.compareTo(a.date));

        final counts = <String, int>{};
        for (final e in entries) {
          for (final m in e.moods) {
            counts[m] = (counts[m] ?? 0) + 1;
          }
        }
        final freq = counts.entries
            .map((e) => MapEntry(
                '${moodById(e.key).emoji} ${moodById(e.key).label}', e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          appBar: AppBar(title: const Text('Historique des humeurs')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              SectionCard(
                title: 'Tendances',
                child: FrequencyBars(
                  data: freq.take(8).toList(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SectionCard(
                title: 'Journal',
                child: entries.isEmpty
                    ? const EmptyHint('Aucune humeur enregistrée.')
                    : Column(
                        children: entries.take(60).map((e) {
                          final info = appState.engine.infoFor(e.date);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${fmtCourt(e.date)} · Jour ${info.dayOfCycle}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(e.moods
                                    .map((id) =>
                                        '${moodById(id).emoji} ${moodById(id).label}')
                                    .join(' · ')),
                                if (e.note.isNotEmpty)
                                  Text('« ${e.note} »',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
