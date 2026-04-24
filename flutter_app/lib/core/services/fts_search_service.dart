import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_app/core/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class FtsSearchService {
  // Use an AND query first, then fallback to OR for better recall.
  static Future<List<String>> searchContext(String userQuery, {Database? dbOverride}) async {
    final db = dbOverride ?? await DatabaseHelper.database;

    final cleanQuery = userQuery.replaceAll(RegExp("['\"]"), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    final words = cleanQuery
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    // Prefix matching on each token (e.g., reverse* string* c#*).
    final andQuery = words.map((w) => '$w*').join(' ');
    final orQuery = words.map((w) => '$w*').join(' OR ');

    try {
      final List<Map<String, dynamic>> andResults = await db.rawQuery('''
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
      ''', [andQuery]);

      if (andResults.isNotEmpty) {
        return andResults.map((row) => row['chunk'] as String).toList();
      }

      // Fallback query for user phrasing mismatches.
      final List<Map<String, dynamic>> orResults = await db.rawQuery('''
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
      ''', [orQuery]);

      if (orResults.isEmpty) return [];
      return orResults.map((row) => row['chunk'] as String).toList();
      
    } catch (e) {
      debugPrint("Search Error: $e");
      return [];
    }
  }
}