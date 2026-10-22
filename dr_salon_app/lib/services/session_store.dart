import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SessionStore {
  static File? _cached;

  @visibleForTesting
  static void resetForTest() {
    _cached = null;
  }

  static Future<File> file() async {
    if (_cached != null) {
      return _cached!;
    }
    Directory root;
    try {
      root = await getApplicationSupportDirectory();
    } catch (_) {
      root = Directory.systemTemp;
    }
    final dir = Directory('${root.path}${Platform.pathSeparator}DrSalonApp');
    dir.createSync(recursive: true);
    _cached = File('${dir.path}${Platform.pathSeparator}session.json');
    return _cached!;
  }

  static Future<Map<String, dynamic>> read() async {
    final target = await file();
    if (!target.existsSync()) {
      return {};
    }
    final decoded = jsonDecode(target.readAsStringSync());
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<void> write(Map<String, dynamic> data) async {
    final target = await file();
    target.writeAsStringSync(jsonEncode(data));
  }

  static Future<void> clear() async {
    final target = await file();
    if (target.existsSync()) {
      target.deleteSync();
    }
  }
}
