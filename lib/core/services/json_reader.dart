import 'dart:convert';

import 'package:flutter/services.dart';

class JsonReaderService {
  JsonReaderService();

  Future<List<dynamic>> readList(String assetPath) async {
    return JsonReaderService._readList(assetPath);
  }

  static Future<List<dynamic>> readListStatic(String assetPath) async {
    return JsonReaderService._readList(assetPath);
  }

  static Future<List<dynamic>> _readList(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw FormatException('Expected a JSON array in $assetPath');
    }

    return decoded;
  }
}
