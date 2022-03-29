class RecentlyPlayed {
  int id;
  int episodeId;
  String currentDuration;

  RecentlyPlayed(this.id, this.episodeId, this.currentDuration);

  RecentlyPlayed.fromJson(Map<String, dynamic> data) {
    id = data['id'];
    episodeId = data['episodeId'];
    currentDuration = data['currentDuration'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'episodeId': episodeId,
      'currentDuration': currentDuration,
    };
  }

  /// Gets the object at specified key.
  /// This doesn't return the object reference. Instead it returns a clone.
  dynamic operator [](String key) => toJson()[key];
}
