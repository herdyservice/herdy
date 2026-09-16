import "../intercourse_screen.dart";
import "../common.dart";
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/cycle_engine.dart';
import '../core/date_utils.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'intercourse_screen.dart';
import 'mood_screen.dart';
import 'symptom_screen.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime date;
  const DayDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final day = dOnly(date);
        final engine = appState.engine;
        final info = engine.infoFor(day);
        final mood = appState.moodOn(day);
        final symptoms = appState.symptomsOn(day);
        final rapports = appState.intercourseOn(day);
        final isStart = engine.hasRecordedStart(day);

        return Scaffold(
          appBar: AppBar(title: Text(fmtCourt(day))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              SectionCard(
                title: fmtFr(day),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jour ${info.dayOfCycle} / ${info.cycleLength}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                        '${phaseEmoji(info.phase)} ${phaseLabel(info.phase)}'),
                    const SizedBox(height: 6),
                    if (info.isPeriod)
                      Text(info.isPeriodRecorded
                          ? '🔴 Règles enregistrées'
                          : '🔴 Règles estimées'),
                    if (info.isFertile && !info.isPeriod)
                      const Text('🌱 Fenêtre fertile estimée'),
                    if (info.isOvulation) const Text('⭐ Ovulation estimée'),
                  ],
                ),
              ),
              SectionCard(
                title: 'Règles',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => appState.togglePeriodStart(day),
                          icon: Icon(isStart
                              ? Icons.close
                              : Icons.play_circle_outline),
                          label: Text(isStart
                              ? 'Retirer ce début de règles'
                              : 'Marquer le début des règles'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => appState.setPeriodEnd(day),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Marquer la fin'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Modifier ces dates recalcule immédiatement les prédictions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Humeur 😊',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mood == null || mood.moods.isEmpty)
                      const EmptyHint('Rien d\u2019enregistré ce jour-là.')
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: mood.moods.map((id) {
                          final m = moodById(id);
                          return Chip(label: Text('${m.emoji} ${m.label}'));
                        }).toList(),
                      ),
                    if (mood != null && mood.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('« ${mood.note} »',
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MoodScreen(date: day)),
                      ),
                      child: const Text('Modifier l\u2019humeur'),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Symptômes 🤕',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (symptoms.isEmpty)
                      const EmptyHint('Aucun symptôme enregistré.')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: symptoms
                            .map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                      '• ${s.name} — ${intensiteLabels[s.intensity]}'),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SymptomScreen(date: day)),
                      ),
                      child: const Text('Modifier les symptômes'),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Rapports 💕',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rapports.isEmpty)
                      const EmptyHint('Aucun rapport enregistré.')
                    else
                      Column(
                        children: rapports
                            .map(
                              (r) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Text('💕',
                                    style: TextStyle(fontSize: 20)),
                                title: Text(r.time == null
                                    ? 'Rapport'
                                    : 'Rapport à ${r.time}'),
                                subtitle: Text(_protectionLabel(r.protectedSex,
                                    r.condom, r.contraception, r.notes)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      appState.deleteIntercourse(r.id!),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => IntercourseScreen(date: day)),
                      ),
                      child: const Text('Ajouter un rapport'),
                    ),
                  ],
                ),
              ),
              const NoticeBox(text: disclaimerFertile),
            ],
          ),
        );
      },
    );
  }

  static String _protectionLabel(
      bool protege, bool condom, bool contraception, String notes) {
    final parts = <String>[];
    parts.add(protege ? 'Protection : oui' : 'Protection : non');
    if (condom) parts.add('préservatif');
    if (contraception) parts.add('contraception');
    if (notes.isNotEmpty) parts.add(notes);
    return parts.join(' · ');
  }
}
