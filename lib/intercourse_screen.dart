import "common.dart";
import "models.dart";
import "constants.dart";
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class IntercourseScreen extends StatefulWidget {
  final DateTime date;
  const IntercourseScreen({super.key, required this.date});

  @override
  State<IntercourseScreen> createState() => _IntercourseScreenState();
}

class _IntercourseScreenState extends State<IntercourseScreen> {
  late DateTime _date;
  TimeOfDay? _time;
  bool _protected = false;
  bool _condom = false;
  bool _contraception = false;
  final TextEditingController _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = dOnly(widget.date);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = dOnly(d));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    await appState.saveIntercourse(IntercourseEntry(
      date: _date,
      time: _time == null
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      protectedSex: _protected,
      condom: _condom,
      contraception: _contraception,
      notes: _notes.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un rapport 💕')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  subtitle: Text(fmtFr(_date)),
                  trailing: TextButton(
                      onPressed: _pickDate, child: const Text('Changer')),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Heure (facultatif)'),
                  subtitle: Text(_time == null
                      ? 'Non renseignée'
                      : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_time != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _time = null),
                        ),
                      TextButton(
                          onPressed: _pickTime, child: const Text('Choisir')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Protection',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _protected,
                  onChanged: (v) => setState(() => _protected = v),
                  title: const Text('Protection utilisée'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _condom,
                  onChanged: (v) => setState(() {
                    _condom = v ?? false;
                    if (_condom) _protected = true;
                  }),
                  title: const Text('Préservatif'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _contraception,
                  onChanged: (v) => setState(() {
                    _contraception = v ?? false;
                    if (_contraception) _protected = true;
                  }),
                  title: const Text('Contraception'),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Notes (facultatif)',
            child: TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Notes privées…'),
            ),
          ),
          NoticeBox(
            text: disclaimerFertile,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.favorite),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
