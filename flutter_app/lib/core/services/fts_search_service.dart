import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_app/core/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class FtsSearchService {
  
  // Notice the added {Database? dbOverride}
  static Future<List<String>> searchContext(String userQuery, {Database? dbOverride}) async {
    // Use the override if provided (for tests), otherwise use the app's DatabaseHelper
    final db = dbOverride ?? await DatabaseHelper.database;

    final cleanQuery = userQuery.replaceAll(RegExp("['\"]"), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    final words = cleanQuery.split(' ').where((w) => w.isNotEmpty).toList();
    final matchQuery = '${words.join(' ')}*';

    try {
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT 
          qa_index.chunk, 
          metadata.score, 
          metadata.is_accepted,
          bm25(qa_index, 1.0, 0.3, 0.8) as rank_score
        FROM qa_index
        JOIN metadata ON qa_index.rowid = metadata.rowid
        WHERE qa_index MATCH ?
        ORDER BY 
          metadata.is_accepted DESC,
          rank_score ASC
        LIMIT 3;
      ''', [matchQuery]);

      if (results.isEmpty) return [];
      return results.map((row) => row['chunk'] as String).toList();
      
    } catch (e) {
      debugPrint("Search Error: $e");
      return [];
    }
  }
}