import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'package:auditory/models/Episode.dart';

class EpisodesProvider {
  static final EpisodesProvider _instance = EpisodesProvider._();
  static bool _isInit = false;

  Database _database;

  final String _tblEpisodes = 'Episodes';
  // final String _tblEpisodeExecutions = 'EpisodeExecutions';

  EpisodesProvider._() {
    _init();
  }

  bool get isReady => _isInit;

  Future<Database> _init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final documentsDirectory = appDocDir.path;
    Database _db;

    _database = await openDatabase(join(documentsDirectory, 'episodes.db'),
        version: 1, onCreate: (Database db, int version) {
      _db = db;
      debugPrint('on database create');
      _createTables(db: db);
    }, onUpgrade: (Database db, int oldVersion, int newVersion) {
      _db = db;
      debugPrint('on database upgrade');
      _dropTables(db: db);
      _createTables(db: db);
    }, onOpen: (Database db) {
      _db = db;
      debugPrint('on database open');
    });

    _isInit = true;

    return _database ?? (_database = _db);
  }

  _dropTables({Database db}) async {
    db ??= _database;
    await db.execute('DROP TABLE $_tblEpisodes');
  }

  _createTables({Database db}) async {
    debugPrint('database tables created.');

    db ??= _database;

    await db.transaction((Transaction tx) async {
      await tx.execute('''
      CREATE TABLE $_tblEpisodes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          episodeId INTEGER,
          taskId TEXT,
          name TEXT,
          podcastName TEXT,
          summary TEXT,
          image TEXT
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

  static EpisodesProvider getInstance() {
    if (_isInit == false) {
      _instance._init();
    }
    return _instance;
  }

  /// Deletes a episode based on its id.
  Future<bool> removeEpisode(int episodeId) async {
    Database db = await _init();
    _database ??= db;

    int r = 0;

    await _database.transaction((Transaction tx) async {
      r = await tx.rawDelete(
          'DELETE FROM $_tblEpisodes '
          'WHERE id = ?',
          [episodeId]);

      /*await tx.rawDelete('''
        DELETE FROM $_tblEpisodeExecutions
        WHERE id = $episodeId;
      ''');*/
    });

    return r != 0;
  }

  /// Inserts a new episode.
  Future<bool> addEpisode(final Episode episode) async {
    Database db = await _init();
    _database ??= db;

    final int i = await _database.rawInsert(
        'INSERT INTO $_tblEpisodes '
        'VALUES (NULL, ?, ?, ?, ?, ?, ?)',
        [
          episode.episodeId,
          episode.taskId,
          episode.name,
          episode.podcastName,
          episode.summary,
          episode.image,
        ]);

    return i >= 1;
  }

  /// Updates the given episode using [Episode.id]
  Future<bool> updateEpisode(final Episode episode) async {
    Database db = await _init();
    _database ??= db;

    final int i = await _database.rawUpdate(
        'UPDATE $_tblEpisodes '
        'SET episodeId = ?, '
        'taskId = ?, '
        'name = ?, '
        'podcastName = ?, '
        'summary = ?, '
        'image = ?, '
        'WHERE id = ?',
        [
          episode.episodeId,
          episode.taskId,
          episode.name,
          episode.podcastName,
          episode.summary,
          episode.image,
          episode.id
        ]);

    return i >= 1;
  }

  /// Gets a episode using its id.
  Future<bool> getEpisode(int id) async {
    Database db = await _init();
    _database ??= db;

    final List<Map<String, dynamic>> rows = await _database
        .rawQuery('SELECT * FROM $_tblEpisodes WHERE episodeId = $id;');

    if (rows.length == 0)
      return false;
    else {
      return true;
    }
  }

  /// Gets the episodes.
  Future<List<Episode>> getEpisodes() async {
    Database db = await _init();
    _database ??= db;

    final List<Map<String, dynamic>> rows =
        await _database.rawQuery('SELECT * FROM $_tblEpisodes;');
    final List<Episode> episodes = List();

    rows.forEach(
        (Map<String, dynamic> row) => episodes.add(Episode.fromJson(row)));

    return episodes;
  }

  Future<List<Episode>> getAllEpisodes() => getEpisodes();

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
    await _database.rawQuery("DELETE FROM $_tblEpisodes;");
    return true;
  }
}
