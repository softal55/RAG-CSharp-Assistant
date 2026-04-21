import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_app/core/services/fts_search_service.dart';

void main() {
  late Database db;

  // Run this once before all tests
  setUpAll(() async {
    // Initialize FFI so SQLite can run on your Windows/Mac machine
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Point directly to the DB file you generated with Python!
    // Since tests run from the flutter_app root, this path maps directly to the asset.
    final path = '${Directory.current.path}/assets/csharp_knowledge.db';

    // Ensure the database actually exists before testing
    expect(
      File(path).existsSync(),
      isTrue,
      reason: "Database file not found at $path",
    );

    // Open the DB using the FFI factory
    db = await databaseFactory.openDatabase(path);
  });

  // Close the DB when all tests are done
  tearDownAll(() async {
    await db.close();
  });

  group('FtsSearchService Offline RAG Tests', () {
    test('Empty query should return an empty list', () async {
      final results = await FtsSearchService.searchContext('', dbOverride: db);
      expect(results, isEmpty);
    });

    test(
      'Searching for "reverse string" should return relevant C# context',
      () async {
        final results = await FtsSearchService.searchContext(
          'reverse string',
          dbOverride: db,
        );

        // Verify we got results
        expect(results, isNotEmpty);

        // Verify we respect the LIMIT 3 constraint to protect LLM memory
        expect(results.length, lessThanOrEqualTo(3));

        // Print the top result to the console so you can see your data pipeline worked!
        debugPrint('--- TOP RESULT FOR "reverse string" ---');
        debugPrint(results.first);
        debugPrint('---------------------------------------');

        // The results should contain the word "reverse"
        expect(results.first.toLowerCase(), contains('reverse'));
      },
    );

    test(
      'Searching for a highly specific C# concept (async await) should return results',
      () async {
        final results = await FtsSearchService.searchContext(
          'async await best practices',
          dbOverride: db,
        );

        expect(results, isNotEmpty);
        debugPrint('--- TOP RESULT FOR "async await best practices" ---');
        debugPrint(results.first);
        debugPrint('---------------------------------------');
      },
    );
  });
}
