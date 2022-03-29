import 'dart:async';

import 'package:auditory/DatabaseFunctions/EpisodesProvider.dart';
import 'package:auditory/models/Episode.dart';

/// Episode Bloc.

class EpisodeBloc {
  final _mp = EpisodesProvider.getInstance();

  void loadEpisodes() async {
    final messages = await _mp.getEpisodes();
  }

  void truncateTables() async {
    await _mp.truncateTables();
  }

  void deleteAllEpisodes() {
    truncateTables();
  }

  Future<bool> addEpisode(final Episode message) async {
    final bool r = await _mp.addEpisode(message);
    return r;
  }

  Future<bool> updateEpisode(final Episode message) async {
    final bool r = await _mp.updateEpisode(message);
    print('updateEpisode');
    return r;
  }
}
