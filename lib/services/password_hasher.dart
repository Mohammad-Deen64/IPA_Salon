import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class PasswordHasher {
  static const _iterations = 200000;
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: 256,
  );

  static Future<String> hash(String password) async {
    final salt = _randomBytes(16);
    final secret = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final digest = await secret.extractBytes();
    return '${_hex(salt)}\$${_hex(digest)}';
  }

  static Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 2) {
      return false;
    }
    final salt = _unhex(parts[0]);
    final expected = _unhex(parts[1]);
    if (salt == null || expected == null) {
      return false;
    }
    final secret = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final digest = await secret.extractBytes();
    if (digest.length != expected.length) {
      return false;
    }
    var different = 0;
    for (var i = 0; i < digest.length; i++) {
      different |= digest[i] ^ expected[i];
    }
    return different == 0;
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  static String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static Uint8List? _unhex(String value) {
    if (value.length.isOdd) {
      return null;
    }
    try {
      final out = Uint8List(value.length ~/ 2);
      for (var i = 0; i < out.length; i++) {
        out[i] = int.parse(value.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}
