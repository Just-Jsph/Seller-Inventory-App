import 'package:sqflite/sqflite.dart';

/// Database contract defining lifecycle and access interface
abstract class DatabaseContract {
  Future<Database> get database;
  Future<void> close();
  Future<void> deleteDb({String? customPath});
}
