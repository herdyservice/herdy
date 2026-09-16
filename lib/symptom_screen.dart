import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class SymptomScreen extends StatefulWidget {
  final DateTime date;
  const SymptomScreen({super.key, required this.date});

  @override
  State<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> {
  final Map<String, int> _intensities = <String, int>{};
  final TextEditingController _autre = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final s in appState.symptomsOn(widget.date)) {
      _intensities[s.name] = s.intensity;
    }
  }

  @override
  void dispose() {
    _autre.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final day = dOnly(widget.date);
    final list = <SymptomEntry>[];
    _intensities.forEach((name, intensity) {
      if (intensity > 0) {
        final label = (name == 'Autre' && _autre.text.trim().isNotEmpty)
            ? _autre.text.trim()
            : name;
        list.add(SymptomEntry(date: day, name: label, intensity: intensity));
      }
    });
    await appState.saveSymptoms(day, list);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Symptômes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Text(fmtFr(dOnly(widget.date)),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Sélectionne et règle l\u2019intensité',
            child: Column(
              children: symptomOptions.map((name) {
                final value = _intensities[name] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: value > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: value > 0 ? scheme.primary : null,
                              ),
                            ),
                          ),
                          Text(intensiteLabels[value],
                              style: TextStyle(
                                  fontSize: 12, color: scheme.outline)),
                        ],
                      ),
                      Row(
                        children: List.generate(4, (i) {
                          final selected = value == i;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  backgroundColor: selected
                                      ? scheme.primary.withOpacity(0.15)
                                      : null,
                                  side: BorderSide(
                                    color: selected
                                        ? scheme.primary
                                        : scheme.outlineVariant,
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _intensities[name] = i),
                                child: Text(
                                  i == 0 ? '—' : '$i',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (name == 'Autre' && value > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextField(
                            controller: _autre,
                            decoration: const InputDecoration(
                              hintText: 'Préciser le symptôme',
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const NoticeBox(text: disclaimerMedical),
          const SizedBox(height: 14),
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
