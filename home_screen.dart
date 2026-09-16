import 'package:flutter/material.dart';

import '../core/advice.dart';
import '../core/constants.dart';
import '../core/cycle_engine.dart';
import '../core/date_utils.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'calendar_screen.dart';
import 'intercourse_screen.dart';
import 'mood_screen.dart';
import 'period_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'symptom_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final today = dOnly(DateTime.now());
        final info = appState.engine.infoFor(today);
        final mood = appState.moodOn(today);
        final symptoms = appState.symptomsOn(today);
        final rapports = appState.intercourseOn(today);
        final conseils = adviceFor(
          info: info,
          symptoms: symptoms,
          mood: mood,
          prenom: appState.settings.name,
        );
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ma Sorcière ❤️'),
            actions: [
              IconButton(
                tooltip: 'Statistiques',
                icon: const Icon(Icons.insights_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StatsScreen())),
              ),
              IconButton(
                tooltip: 'Paramètres',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              _header(context, info),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(context, '🗓️', 'Prochaines règles estimées',
                        fmtFr(info.nextStart)),
                    const Divider(height: 22),
                    _line(context, phaseEmoji(info.phase), 'Phase actuelle',
                        phaseLabel(info.phase)),
                    const Divider(height: 22),
                    _line(context, '⭐', 'Ovulation estimée',
                        fmtFr(info.ovulation)),
                    const Divider(height: 22),
                    _line(
                      context,
                      '🌱',
                      'Fenêtre fertile estimée',
                      '${fmtCourt(info.fertileStart)} → ${fmtCourt(info.fertileEnd)}',
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: "Aujourd'hui",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('😊 '),
                        Expanded(
                          child: mood == null || mood.moods.isEmpty
                              ? const EmptyHint('Aucune humeur enregistrée.')
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: mood.moods.map((id) {
                                    final m = moodById(id);
                                    return Chip(
                                      label: Text('${m.emoji} ${m.label}'),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤕 '),
                        Expanded(
                          child: symptoms.isEmpty
                              ? const EmptyHint('Aucun symptôme enregistré.')
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: symptoms
                                      .map((s) => Chip(
                                            label: Text(
                                                '${s.name} · ${intensiteLabels[s.intensity]}'),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ))
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                    if (rapports.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('💕 '),
                          Text(rapports.length == 1
                              ? '1 rapport enregistré'
                              : '${rapports.length} rapports enregistrés'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SectionCard(
                title: 'Conseils du jour 🧠',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: conseils
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: a.warning
                                ? NoticeBox(
                                    text: a.text,
                                    icon: Icons.health_and_safety_outlined,
                                    color: scheme.error,
                                  )
                                : Text(a.text,
                                    style: const TextStyle(height: 1.45)),
                          ))
                      .toList(),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  ActionTile(
                    emoji: '😊',
                    label: 'Ajouter une humeur',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MoodScreen(date: today))),
                  ),
                  ActionTile(
                    emoji: '🤕',
                    label: 'Ajouter un symptôme',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SymptomScreen(date: today))),
                  ),
                  ActionTile(
                    emoji: '💕',
                    label: 'Ajouter un rapport',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => IntercourseScreen(date: today))),
                  ),
                  ActionTile(
                    emoji: '📅',
                    label: 'Calendrier',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CalendarScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PeriodScreen())),
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Suivi des règles'),
              ),
              const SizedBox(height: 14),
              const NoticeBox(text: disclaimerFertile),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, CycleInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.rose.withOpacity(0.85),
            AppTheme.lavande.withOpacity(0.85),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            appState.settings.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          CycleRing(
            day: info.dayOfCycle,
            total: info.cycleLength,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Jour',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(
                  '${info.dayOfCycle} / ${info.cycleLength}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phaseLabel(info.phase),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            info.daysUntilNext <= 0
                ? 'Règles estimées aujourd\u2019hui'
                : 'Règles estimées dans ${info.daysUntilNext} jour${info.daysUntilNext > 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fmtFr(dOnly(DateTime.now())),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
