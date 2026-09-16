import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'day_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Calendrier')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    fmtMoisAnnee(_month),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: joursFr
                    .map((j) => Expanded(
                          child: Center(
                            child: Text(
                              j,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              _grid(context),
              const SizedBox(height: 18),
              SectionCard(
                title: 'Légende',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Legend('🔴', 'Règles (enregistrées ou estimées)'),
                    _Legend('🌱', 'Fenêtre fertile estimée'),
                    _Legend('⭐', 'Ovulation estimée'),
                    _Legend('💕', 'Rapport enregistré'),
                    _Legend('😊', 'Humeur enregistrée'),
                    _Legend('🤕', 'Symptômes enregistrés'),
                  ],
                ),
              ),
              const NoticeBox(text: disclaimerFertile),
              const SizedBox(height: 10),
              Text(
                'Astuce : touche une date pour voir son détail, marquer le début '
                'ou la fin des règles et corriger les prédictions.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grid(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday - 1; // lundi = 0
    final cells = <Widget>[];

    for (var i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_dayCell(context, DateTime(_month.year, _month.month, d)));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 0.72,
      children: cells,
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final engine = appState.engine;
    final info = engine.infoFor(day);
    final scheme = Theme.of(context).colorScheme;
    final isToday = sameDay(day, DateTime.now());

    final recorded = info.isPeriodRecorded;
    final predicted = !recorded && info.isPeriod;

    Color bg = Colors.transparent;
    Color border = Colors.transparent;
    if (recorded) {
      bg = AppTheme.rose.withOpacity(0.85);
    } else if (predicted) {
      bg = AppTheme.rose.withOpacity(0.20);
      border = AppTheme.rose.withOpacity(0.55);
    } else if (info.isOvulation) {
      bg = AppTheme.or.withOpacity(0.28);
      border = AppTheme.or;
    } else if (info.isFertile) {
      bg = AppTheme.vert.withOpacity(0.18);
    }

    final marks = <String>[];
    if (appState.intercourseOn(day).isNotEmpty) marks.add('💕');
    final mood = appState.moodOn(day);
    if (mood != null && (mood.moods.isNotEmpty || mood.note.isNotEmpty)) {
      marks.add('😊');
    }
    if (appState.symptomsOn(day).isNotEmpty) marks.add('🤕');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DayDetailScreen(date: day)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? scheme.primary : border,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: recorded ? Colors.white : null,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 22,
              child: Text(
                marks.join(),
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String emoji;
  final String label;
  const _Legend(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
