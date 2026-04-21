import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class DatabaseHelper {
  static const String dbName = "csharp_knowledge.db";
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);

    // Check if the database already exists on the device
    bool dbExists = await File(path).exists();

    if (!dbExists) {
      debugPrint("First launch: Copying database from assets to device...");
      // Copy from asset
      ByteData data = await rootBundle.load(join("assets/db", dbName));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Write to device
      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint("Database copied successfully!");
    } else {
      debugPrint("Database already exists on device.");
    }

    return await openDatabase(path);
  }
}