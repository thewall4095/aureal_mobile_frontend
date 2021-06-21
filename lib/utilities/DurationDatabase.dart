import 'dart:io';

import 'package:auditory/models/RecentlyPlayedModal.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class RecentlyPlayedProvider {
  static final RecentlyPlayedProvider _instance = RecentlyPlayedProvider._();

  static bool _isInit = false;
  Database _database;

  final _tblRecentlyPlayed = 'recentlyplayed';

  RecentlyPlayedProvider._() {
    _init();
  }

  bool get isReady => _isInit;

  Future<Database> _init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final documentsDirectory = appDocDir.path;
    Database _db;

    _database = await openDatabase(
        join(documentsDirectory, 'recentlyplayed.db'),
        version: 1, onCreate: (Database db, int version) {
      _db = db;
      debugPrint('on database create recentlyplayed');
      _createTables(db: db);
    }, onUpgrade: (Database db, int oldVersion, int newVersion) {
      _db = db;
      debugPrint('on database upgrade recentlyplayed');
      _dropTables(db: db);
      _createTables(db: db);
    }, onOpen: (Database db) {
      debugPrint('on database open recentlyplayed');

      _db = db;
    });

    _isInit = true;

    return _database ?? (_database = _db);
  }

  _dropTables({Database db}) async {
    db ??= _database;
    await db.execute('DROP TABLE $_tblRecentlyPlayed');
  }

  _createTables({Database db}) async {
    debugPrint('database tables created.');

    db ??= _database;

    await db.transaction((Transaction tx) async {
      await tx.execute('''
      CREATE TABLE $_tblRecentlyPlayed (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          episodeId INTEGER,
          currentDuration TEXT
        );
      ''');

      /*await tx.execute('''CREATE TABLE $_tblEpisodeExecutions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          episode_id INTEGER,
          status INTEGER
        );
      '''); */
    });
  }

  static RecentlyPlayedProvider getInstance() {
    if (_isInit == false) {
      _instance._init();
    }
    return _instance;
  }

  Future<bool> removeEpisode(int episodeId) async {
    Database db = await _init();
    _database ??= db;

    int r = 0;

    await _database.transaction((Transaction tx) async {
      r = await tx.rawDelete(
          'DELETE FROM $_tblRecentlyPlayed '
          'WHERE id = ?',
          [episodeId]);

      /*await tx.rawDelete('''
        DELETE FROM $_tblEpisodeExecutions
        WHERE id = $episodeId;
      ''');*/
    });

    return r != 0;
  }

  Future<Duration> getEpisodeDuration(var episodeId) async {
    print(
        "Its coming here //////////////////////////////////////////////////////////////");

    print(episodeId);
    Database db = await _init();
    _database ??= db;

    var rows = await _database.rawQuery(
        'SELECT * FROM $_tblRecentlyPlayed WHERE episodeId = $episodeId;');

    if (rows.length != 0) {
      print(
          '${rows[0]['currentDuration']} ////////////////////////////////////////////////');
      print(Duration(
          minutes:
              int.parse(rows[0]['currentDuration'].toString().split(':')[1]),
          seconds: int.parse(rows[0]['currentDuration']
              .toString()
              .split(':')[2]
              .split('.')[0]),
          hours:
              int.parse(rows[0]['currentDuration'].toString().split(':')[0])));
      return Duration(
          minutes:
              int.parse(rows[0]['currentDuration'].toString().split(':')[1]),
          seconds: int.parse(rows[0]['currentDuration']
              .toString()
              .split(':')[2]
              .split('.')[0]),
          hours:
              int.parse(rows[0]['currentDuration'].toString().split(':')[0]));
    } else {
      return null;
    }

    // print(rows.first);

    // if (rows.length != 0) {
    //   print(rows);
    //   // return rows[0];
    // } else {
    //   // return null;
    // }
  }

  void addToDatabase(var episodeId, var currentPosition) {
    if (getEpisode(episodeId) == true) {
      print(
          'update episode called /////////////////////////////////////////////');
      updateEpisode(episodeId, currentPosition);
    } else {
      print(
          'add episode called//////////////////////////////////////////////////');
      addEpisode(episodeId, currentPosition);
    }
  }

  Future<bool> addEpisode(var episodeId, var currentPosition) async {
    Database db = await _init();
    _database ??= db;

    // print('$episodeId $currentPosition');

    final int i = await _database.rawInsert(
        'INSERT INTO $_tblRecentlyPlayed '
        'VALUES (NULL, ?, ?)',
        [
          episodeId,
          currentPosition.toString(),
        ]);

    return i >= 1;
  }

  /// Updates the given episode using [Episode.id]
  Future<bool> updateEpisode(var episodeId, var currentPosition) async {
    Database db = await _init();
    _database ??= db;

    final int i = await _database.rawUpdate(
        'UPDATE $_tblRecentlyPlayed '
        'SET episodeId = ?, '
        'currentDuration = ?, '
        'WHERE id = ?',
        [
          episodeId,
          currentPosition,
        ]);

    return i >= 1;
  }

  /// Gets a episode using its id.
  Future<bool> getEpisode(var id) async {
    Database db = await _init();
    _database ??= db;

    final List<Map<String, dynamic>> rows = await _database
        .rawQuery('SELECT * FROM $_tblRecentlyPlayed WHERE episodeId = $id;');

    if (rows.length == 0)
      return false;
    else {
      return true;
    }
  }

  /// Gets the episodes.
  Future<List> getEpisodes() async {
    Database db = await _init();
    _database ??= db;

    final List<Map<String, dynamic>> rows =
        await _database.rawQuery('SELECT * FROM $_tblRecentlyPlayed;');
    final List<RecentlyPlayed> episodes = List();

    rows.forEach((Map<String, dynamic> row) =>
        episodes.add(RecentlyPlayed.fromJson(row)));

    return episodes;
  }

  Future<List<RecentlyPlayed>> getAllEpisodes() => getEpisodes();

  /// Empties the tables.
  Future<bool> deleteAllEpisodes() {
    return truncateTables();
  }

  /// Frees the database resources.
  void dispose() {
    if (_database != null && _database.isOpen) {
      debugPrint('on close database');
      _database.close().then((_) => _database = null);
    }
  }

  /// Empties the tables.
  Future<bool> truncateTables() async {
    await _database.rawQuery("DELETE FROM $_tblRecentlyPlayed;");
    return true;
  }
}
