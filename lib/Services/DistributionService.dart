import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> getSharableLink(int podcastId) async {
  String url =
      "https://api.aureal.one/public/distributionStatus?podcast_id=$podcastId";
  print(url);

  try {
    http.Response response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      print(jsonDecode(response.body)['allDistributions'][0]['link']);
      return jsonDecode(response.body)['allDistributions'][0]['link'];
    } else {
      return 0.toString();
    }
  } catch (e) {
    print(e);
  }
}
