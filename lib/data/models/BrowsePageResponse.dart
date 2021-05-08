import 'DiscoverPageResponse.dart';
import 'HomePageResponse.dart';

class BrowsePageResponse {
  List<LiveStreams> newEpisodes;
  List<RecommendedCategories> categories;

  BrowsePageResponse({this.newEpisodes, this.categories});

  BrowsePageResponse.fromJson(Map<String, dynamic> json) {
    if (json['live_channels'] != null) {
      newEpisodes = new List<LiveStreams>();
      json['live_channels'].forEach((v) {
        newEpisodes.add(LiveStreams.fromJson(v));
      });
    }

    if (json['categories'] != null) {
      categories = new List<RecommendedCategories>();
      json['categories'].forEach((v) {
        categories.add(RecommendedCategories.fromJson(v));
      });
    }
  }
}
