import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/date_utils.dart';
import '../data/settings.dart';
import '../services/backup_service.dart';
import '../services/security_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _s;
  late TextEditingController _name;
  late TextEditingController _custom;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _s = appState.settings.copy();
    _name = TextEditingController(text: _s.name);
    _custom = TextEditingController(text: _s.customTitle);
    SecurityService.biometricAvailable().then((v) {
      if (mounted) setState(() => _biometricAvailable = v);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _custom.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    _s.name = _name.text.trim().isEmpty ? 'Ma Sorcière' : _name.text.trim();
    await appState.saveSettings(_s.copy());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres enregistrés ✅')),
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres ⚙️')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          SectionCard(
            title: 'Profil',
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                const SizedBox(height: 14),
                _numberRow(
                  label: 'Durée habituelle du cycle',
                  value: _s.cycleLength,
                  min: 18,
                  max: 45,
                  suffix: 'jours',
                  onChanged: (v) => setState(() => _s.cycleLength = v),
                ),
                _numberRow(
                  label: 'Durée habituelle des règles',
                  value: _s.periodLength,
                  min: 1,
                  max: 12,
                  suffix: 'jours',
                  onChanged: (v) => setState(() => _s.periodLength = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dernier début des règles'),
                  subtitle: Text(fmtFr(_s.lastStart)),
                  trailing: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _s.lastStart,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setState(() => _s.lastStart = dOnly(d));
                      }
                    },
                    child: const Text('Changer'),
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Notifications 🔔',
            child: Column(
              children: [
                _switch('Début estimé des règles', _s.notifPeriod,
                    (v) => setState(() => _s.notifPeriod = v)),
                _switch('Approche de la période fertile', _s.notifFertile,
                    (v) => setState(() => _s.notifFertile = v)),
                _switch('Rappel : renseigner l\u2019humeur', _s.notifMood,
                    (v) => setState(() => _s.notifMood = v)),
                _switch('Rappel : renseigner les symptômes', _s.notifSymptom,
                    (v) => setState(() => _s.notifSymptom = v)),
                _switch('Rappel personnalisé', _s.notifCustom,
                    (v) => setState(() => _s.notifCustom = v)),
                if (_s.notifCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _custom,
                    onChanged: (v) => _s.customTitle = v,
                    decoration: const InputDecoration(
                        labelText: 'Texte du rappel personnalisé'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Heure du rappel personnalisé'),
                    subtitle: Text(
                        '${_s.customHour.toString().padLeft(2, '0')}:${_s.customMinute.toString().padLeft(2, '0')}'),
                    trailing: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: _s.customHour, minute: _s.customMinute),
                        );
                        if (t != null) {
                          setState(() {
                            _s.customHour = t.hour;
                            _s.customMinute = t.minute;
                          });
                        }
                      },
                      child: const Text('Changer'),
                    ),
                  ),
                ],
                _numberRow(
                  label: 'Heure des rappels quotidiens',
                  value: _s.reminderHour,
                  min: 6,
                  max: 23,
                  suffix: 'h',
                  onChanged: (v) => setState(() => _s.reminderHour = v),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Apparence',
            child: Wrap(
              spacing: 8,
              children: [
                _themeChip('Système', 'system'),
                _themeChip('Clair', 'light'),
                _themeChip('Sombre', 'dark'),
              ],
            ),
          ),
          SectionCard(
            title: 'Confidentialité 🔐',
            child: Column(
              children: [
                _switch(
                  'Verrouiller l\u2019application par code PIN',
                  _s.lockEnabled,
                  (v) async {
                    if (v) {
                      final pin = await _askPin();
                      if (pin == null) return;
                      setState(() {
                        _s.pinHash = SecurityService.hashPin(pin);
                        _s.lockEnabled = true;
                      });
                    } else {
                      setState(() {
                        _s.lockEnabled = false;
                        _s.biometric = false;
                        _s.pinHash = '';
                      });
                    }
                  },
                ),
                if (_s.lockEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Modifier le code PIN'),
                    trailing: TextButton(
                      onPressed: () async {
                        final pin = await _askPin();
                        if (pin != null) {
                          setState(
                              () => _s.pinHash = SecurityService.hashPin(pin));
                          _snack('Code PIN mis à jour');
                        }
                      },
                      child: const Text('Changer'),
                    ),
                  ),
                if (_s.lockEnabled && _biometricAvailable)
                  _switch('Déverrouillage biométrique', _s.biometric,
                      (v) => setState(() => _s.biometric = v)),
                const SizedBox(height: 6),
                const NoticeBox(
                  text:
                      'Toutes tes données restent sur ce téléphone. Aucune information '
                      'n\u2019est envoyée à un serveur, et l\u2019application fonctionne '
                      'entièrement hors connexion.',
                  icon: Icons.lock_outline,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Sauvegarde',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Exporter une sauvegarde'),
                  subtitle: const Text('Fichier JSON local + copie possible'),
                  onTap: _export,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Importer une sauvegarde'),
                  subtitle: const Text('Colle le contenu du fichier JSON'),
                  onTap: _import,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_outlined,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Effacer toutes les données',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  onTap: _eraseAll,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _apply,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer les paramètres'),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Ma Sorcière ❤️ · version 1.0.0',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, void Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(label),
    );
  }

  Widget _themeChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _s.themeMode == value,
      onSelected: (_) => setState(() => _s.themeMode = value),
    );
  }

  Widget _numberRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required void Function(int) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 56,
            child: Text('$value $suffix',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Future<String?> _askPin() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau code PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '4 à 8 chiffres'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (controller.text.length >= 4) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    final result = await BackupService.export(appState.settings);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sauvegarde locale'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.path != null)
                Text('Fichier enregistré :\n${result.path}',
                    style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              const Text(
                  'Tu peux aussi copier le contenu ci-dessous et le conserver où tu veux.'),
              const SizedBox(height: 10),
              Container(
                height: 160,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(ctx).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(result.json,
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.json));
              Navigator.pop(ctx);
              _snack('Sauvegarde copiée dans le presse-papiers');
            },
            child: const Text('Copier'),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer une sauvegarde'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration:
              const InputDecoration(hintText: 'Colle ici le contenu JSON…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final imported = await BackupService.import(raw);
      await appState.applyImportedSettings(imported);
      if (!mounted) return;
      setState(() {
        _s = imported.copy();
        _name.text = _s.name;
      });
      _snack('Sauvegarde importée ✅');
    } catch (e) {
      _snack('Import impossible : $e');
    }
  }

  Future<void> _eraseAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: const Text(
            'Toutes les données enregistrées seront définitivement supprimées de ce téléphone. '
            'Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await appState.eraseEverything();
    if (!mounted) return;
    setState(() {
      _s = appState.settings.copy();
      _name.text = _s.name;
      _custom.text = _s.customTitle;
    });
    _snack('Toutes les données ont été effacées');
  }
}
