import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'mood_history_screen.dart';

class MoodScreen extends StatefulWidget {
  final DateTime date;
  const MoodScreen({super.key, required this.date});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  late Set<String> _selected;
  late TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final existing = appState.moodOn(widget.date);
    _selected = existing == null ? <String>{} : existing.moods.toSet();
    _note = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await appState.saveMood(MoodEntry(
      date: dOnly(widget.date),
      moods: _selected.toList(),
      note: _note.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Humeur du jour'),
        actions: [
          IconButton(
            tooltip: 'Historique',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoodHistoryScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Text(fmtFr(dOnly(widget.date)),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Comment te sens-tu ? (plusieurs choix possibles)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moodOptions.map((m) {
                final sel = _selected.contains(m.id);
                return FilterChip(
                  selected: sel,
                  label: Text('${m.emoji} ${m.label}'),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selected.add(m.id);
                    } else {
                      _selected.remove(m.id);
                    }
                  }),
                );
              }).toList(),
            ),
          ),
          SectionCard(
            title: 'Commentaire (facultatif)',
            child: TextField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Un mot sur ta journée…',
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
