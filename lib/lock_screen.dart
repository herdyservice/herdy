import 'package:flutter/material.dart';

import '../services/security_service.dart';
import '../state/app_state.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _entry = '';
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final ok = await SecurityService.biometricAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = ok);
    if (ok && appState.settings.biometric) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await SecurityService.authenticate();
    if (ok) appState.unlock();
  }

  void _press(String digit) {
    if (_entry.length >= 8) return;
    setState(() {
      _entry += digit;
      _error = null;
    });
    if (_entry.length >= 4) _validate();
  }

  void _validate() {
    if (SecurityService.checkPin(_entry, appState.settings.pinHash)) {
      appState.unlock();
    } else if (_entry.length >= 4) {
      setState(() {
        _error = 'Code incorrect';
      });
    }
  }

  void _erase() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ma Sorcière ❤️',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Entre ton code',
                    style: TextStyle(color: scheme.outline)),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _entry.isEmpty ? 4 : (_entry.length < 4 ? 4 : _entry.length),
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _entry.length
                            ? scheme.primary
                            : scheme.primary.withOpacity(0.18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 22,
                  child: Text(
                    _error ?? '',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 260,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (var i = 1; i <= 9; i++) _key('$i'),
                      _iconKey(
                        Icons.fingerprint,
                        _biometricAvailable && appState.settings.biometric
                            ? _tryBiometric
                            : null,
                      ),
                      _key('0'),
                      _iconKey(Icons.backspace_outlined, _erase),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _key(String digit) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _press(digit),
        child: Center(
          child: Text(digit,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: Icon(
            icon,
            color: onTap == null
                ? Theme.of(context).colorScheme.outlineVariant
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
