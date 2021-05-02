class HomePageResponse {
  List<LiveStreams> liveStreams;
  List<LiveStreams> recommendedEpisodes;
  List<PodcastEpisodes> podcastEpisodes;
  List<Podcast> podcasts;

  HomePageResponse({
    this.liveStreams,
    this.recommendedEpisodes,
    this.podcastEpisodes,
    this.podcasts,
  });

  HomePageResponse.fromJson(Map<String, dynamic> json) {
    if (json['live_streams'] != null) {
      liveStreams = new List<LiveStreams>();
      json['live_streams'].forEach((v) {
        liveStreams.add(new LiveStreams.fromJson(v));
      });
    }
    if (json['recommended_episodes'] != null) {
      recommendedEpisodes = <LiveStreams>[];
      json['recommended_episodes'].forEach((v) {
        recommendedEpisodes.add(new LiveStreams.fromJson(v));
      });
    }
    if (json['offline_channels'] != null) {
      podcastEpisodes = new List<PodcastEpisodes>();
      json['offline_channels'].forEach((v) {
        podcastEpisodes.add(new PodcastEpisodes.fromJson(v));
      });
    }
    if (json['offline_channels'] != null) {
      podcasts = new List<Podcast>();
      json['offline_channels'].forEach((v) {
        podcasts.add(new Podcast.fromJson(v));
      });
    }
  }
}

class LiveStreams {
  String streamerName;
  String streamerAvatar;
  String streamTitle;
  String categoryName;
  String tag;
  String thumbnail;
  String listens;

  LiveStreams({
    this.streamerName,
    this.streamerAvatar,
    this.streamTitle,
    this.categoryName,
    this.tag,
    this.thumbnail,
    this.listens,
  });

  LiveStreams.fromJson(Map<String, dynamic> json) {
    streamerName = json['streamer_name'];
    streamerAvatar = json['streamer_avatar'];
    streamTitle = json['stream_title'];
    categoryName = json['category_name'];
    tag = json['tag'];
    thumbnail = json['thumbnail'];
    listens = json['views'];
  }
}

class PodcastEpisodes {
  String streamerName;
  String streamerAvatar;
  String newEpisodes;

  PodcastEpisodes({this.streamerName, this.streamerAvatar, this.newEpisodes});

  PodcastEpisodes.fromJson(Map<String, dynamic> json) {
    streamerName = json['username'];
    streamerAvatar = json['userAvatar'];
    newEpisodes = json['new_episodes'];
  }
}

class Podcast {
  String streamerName;
  String streamerAvatar;
  String podcast;

  Podcast({this.streamerName, this.streamerAvatar, this.podcast});

  Podcast.fromJson(Map<String, dynamic> json) {
    streamerName = json['streamer_name'];
    streamerAvatar = json['streamer_avatar'];
    podcast = json['new_episodes'];
  }
}
