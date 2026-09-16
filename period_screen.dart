import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class PeriodScreen extends StatelessWidget {
  const PeriodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final engine = appState.engine;
        final periods = appState.periods.reversed.toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Suivi des règles')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            children: [
              SectionCard(
                title: 'Résumé',
                child: Column(
                  children: [
                    _row(context, 'Durée moyenne du cycle',
                        '${engine.averageCycleLength} jours'),
                    _row(context, 'Durée moyenne des règles',
                        '${engine.averagePeriodLengthExact.toStringAsFixed(1)} jours'),
                    _row(context, 'Cycles complets enregistrés',
                        '${engine.recordedCycles}'),
                    _row(context, 'Jour actuel',
                        'Jour ${appState.todayInfo.dayOfCycle}'),
                  ],
                ),
              ),
              SectionCard(
                title: 'Historique',
                child: periods.isEmpty
                    ? const EmptyHint('Aucune période enregistrée.')
                    : Column(
                        children: periods.map((p) {
                          final len = p.length;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Text('🔴',
                                style: TextStyle(fontSize: 20)),
                            title: Text(fmtFr(p.start)),
                            subtitle: Text([
                              p.end == null
                                  ? 'Fin non renseignée'
                                  : 'Fin : ${fmtCourt(p.end!)}',
                              if (len != null) '$len j',
                              'Flux : ${flowOptions[p.flow] ?? p.flow}',
                              'Douleurs : ${intensiteLabels[p.pain]}',
                            ].join(' · ')),
                            onTap: () => _edit(context, p),
                          );
                        }).toList(),
                      ),
              ),
              const NoticeBox(
                text:
                    'Corriger une date de début met automatiquement à jour toutes les prédictions.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, PeriodEntry? entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _PeriodForm(entry: entry),
      ),
    );
  }
}

class _PeriodForm extends StatefulWidget {
  final PeriodEntry? entry;
  const _PeriodForm({this.entry});

  @override
  State<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends State<_PeriodForm> {
  late DateTime _start;
  DateTime? _end;
  late String _flow;
  late int _pain;
  late TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _start = e?.start ?? dOnly(DateTime.now());
    _end = e?.end;
    _flow = e?.flow ?? 'moyenne';
    _pain = e?.pain ?? 0;
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool start}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start ? _start : (_end ?? _start),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (start) {
        _start = dOnly(d);
      } else {
        _end = dOnly(d);
      }
    });
  }

  Future<void> _save() async {
    var end = _end;
    if (end != null && end.isBefore(_start)) end = null;
    await appState.savePeriod(PeriodEntry(
      id: widget.entry?.id,
      start: _start,
      end: end,
      flow: _flow,
      pain: _pain,
      notes: _notes.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.entry?.id != null) {
      await appState.deletePeriod(widget.entry!.id!);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.entry == null ? 'Nouvelles règles' : 'Modifier',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Début'),
            subtitle: Text(fmtFr(_start)),
            trailing: TextButton(
                onPressed: () => _pick(start: true),
                child: const Text('Changer')),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fin'),
            subtitle: Text(_end == null ? 'Non renseignée' : fmtFr(_end!)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_end != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _end = null),
                  ),
                TextButton(
                    onPressed: () => _pick(start: false),
                    child: const Text('Changer')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Intensité des saignements'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: flowOptions.entries
                .map((e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _flow == e.key,
                      onSelected: (_) => setState(() => _flow = e.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('Douleurs : ${intensiteLabels[_pain]}'),
          Slider(
            value: _pain.toDouble(),
            min: 0,
            max: 3,
            divisions: 3,
            label: intensiteLabels[_pain],
            onChanged: (v) => setState(() => _pain = v.round()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Notes personnelles (facultatif)'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (widget.entry != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                  ),
                ),
              if (widget.entry != null) const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
