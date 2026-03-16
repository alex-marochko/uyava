import 'dart:convert';
import 'dart:io';

Future<List<Map<String, dynamic>>> readLogRecords(File file) async {
  final List<int> raw = await file.readAsBytes();
  final List<int> decoded = GZipCodec().decode(raw);
  final String content = utf8.decode(decoded);
  final List<String> lines = content
      .split('\n')
      .where((String line) => line.trim().isNotEmpty)
      .toList();
  return lines
      .map<Map<String, dynamic>>(
        (String line) => jsonDecode(line) as Map<String, dynamic>,
      )
      .toList();
}
