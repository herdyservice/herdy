import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static String hashPin(String pin) =>
      sha256.convert(utf8.encode('ma_sorciere::$pin')).toString();

  static bool checkPin(String pin, String hash) => hashPin(pin) == hash;

  static Future<bool> biometricAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final can = await _auth.canCheckBiometrics;
      if (!can) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Déverrouille Ma Sorcière ❤️',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
