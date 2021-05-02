import 'HomePageResponse.dart';

class DiscoverPageResponse {
  List<TopChannels> topChannels;
  List<RecommendedCategories> recommendedCategories;
  List<LiveStreams> recommendedChannels;

  DiscoverPageResponse(
      this.topChannels, this.recommendedChannels, this.recommendedCategories);

  DiscoverPageResponse.fromJson(Map<String, dynamic> json) {
    if (json['top_channels'] != null) {
      topChannels = new List<TopChannels>();
      json['top_channels'].forEach((v) {
        topChannels.add(new TopChannels.fromJson(v));
      });
    }

    if (json['recommended_channels'] != null) {
      recommendedChannels = new List<LiveStreams>();
      json['recommended_channels'].forEach((v) {
        recommendedChannels.add(new LiveStreams.fromJson(v));
      });
    }

    if (json['recommended_categories'] != null) {
      recommendedCategories = new List<RecommendedCategories>();
      json['recommended_categories'].forEach((v) {
        recommendedCategories.add(new RecommendedCategories.fromJson(v));
      });
    }
  }
}

class RecommendedCategories {
  String categoryName;
  String categoryCover;
  String listenerCount;
  String tag;
  String categoryValue;

  RecommendedCategories(
      {this.categoryName,
      this.categoryCover,
      this.listenerCount,
      this.tag,
      this.categoryValue});

  RecommendedCategories.fromJson(Map<String, dynamic> json) {
    categoryName = json['category_name'];
    categoryCover = json['category_cover'];
    listenerCount = json['views'];
    tag = json['tag'];
    categoryValue = json['category_value'];
  }
}

class TopChannels {
  String streamerName;
  String categoryName;
  String tag;
  String thumbnail;
  String listens;
  String channelValue;

  TopChannels(
      {this.streamerName,
      this.categoryName,
      this.tag,
      this.thumbnail,
      this.listens,
      this.channelValue});

  TopChannels.fromJson(Map<String, dynamic> json) {
    streamerName = json['streamer_name'];
    categoryName = json['category_name'];
    tag = json['tag'];
    thumbnail = json['thumbnail'];
    listens = json['views'];
    channelValue = json['channel_value'];
  }
}
