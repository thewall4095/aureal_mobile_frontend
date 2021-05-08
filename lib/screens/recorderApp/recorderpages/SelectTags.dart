import 'dart:convert';
import 'package:auditory/SelectedCommunitiesProvider.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import '../../Home.dart';

class SelectTags extends StatefulWidget {
  static const String id = "Select Tags";
  int currentEpisodeId;
  var episodeTitle;
  int currentPodcastId;
  var episodeDescription;
  var userID;
  int seasonNum;
  int episodeNumber;
  String episodeImage;
  String author;
  SelectTags(
      {this.userID,
      this.currentPodcastId,
      this.currentEpisodeId,
      this.episodeTitle,
      this.episodeDescription,
      this.episodeNumber,
      this.author,
      this.episodeImage});

  @override
  _SelectTagsState createState() => _SelectTagsState();
}

class _SelectTagsState extends State<SelectTags> {
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  TextEditingController _controller;
  bool isTagsLoading = false;

  postreq.Interceptor intercept = postreq.Interceptor();

  Dio dio = Dio();

//  List<String> addedTagList = List<String>();
//  List<int> addedIdTagList = List<int>();
//  List<String> suggestionTags = List<String>();
//  List<int> tagIdList = List<int>();
  String tagToBeCreated;
  List tags = [];

  List<dynamic> selectedTags = [];

  List<String> x = List<String>();

  String query;

  void updateEpisode(
      {String userID,
      int episodeId,
      String episodeName,
      String description,
      String imageUrl,
      int podcastId,
      List communities,

//      String author,
      bool status}) async {
    String url = 'https://api.aureal.one/private/updateEpisode';

    var map = Map<String, dynamic>();
    map['user_id'] = userID;
    map['episode_id'] = episodeId;
    map['name'] = episodeName;
    map['summary'] = description;
    map['image'] = imageUrl;

//    map['author'] = widget.author;

    String communityIds = '';

    String tagId = '';

    for (var v in communities) {
      communityIds = communityIds + '${v['id']}' + '_';
    }

    print(communityIds);

    for (var v in selectedTags.toSet().toList()) {
      tagId = tagId + v['id'].toString() + '_';
    }
    print(tagId);

    map['tag_ids'] = tagId == '' ? null : tagId;

    FormData formData = FormData.fromMap(map);

    print(map.toString());

    var response = await intercept.postRequest(formData, url);
    print(response.toString());
    publishEpisode(
        episodeID: episodeId,
        podcastID: podcastId,
        status: true,
        communityIDString: communityIds);
//    var data = response.data['episode']['url'];
//    print(data.toString());
  }

  void createTag(String tagTobeCreated) async {
    var map = Map<String, dynamic>();

    map['name'] = tagTobeCreated;

    FormData formData = FormData.fromMap(map);
    var response =
        await dio.post('https://api.aureal.one/public/addTag', data: formData);
    print(response.toString());
  }

  void publishEpisode(
      {int episodeID,
      int podcastID,
      bool status,
      String communityIDString}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/publishEpisode";
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = episodeID;
    map['podcast_id'] = podcastID;
    map['status'] = status;
    map['community_ids'] = communityIDString;

    FormData formData = FormData.fromMap(map);

    print(map.toString());

    var response = await intercept.postRequest(formData, url);
    print(response.toString());
    Navigator.popAndPushNamed(context, Home.id);
  }

  void getTags(String query) async {
    setState(() {
      isTagsLoading = true;
    });

    String url = "https://api.aureal.one/public/getTag?word=$query";
    try {
      http.Response response = await http.get(Uri.parse(url));
      setState(() {
        isTagsLoading = false;
      });
      if (response.statusCode == 200) {
//        suggestionTags = loadTags(response.body);
        setState(() {
          tags = jsonDecode(response.body)['allTags'];
        });
      } else {
        print("error loading tags");
      }
    } catch (e) {
      print(e);
    }
  }

  static List<Tag> loadTags(String jsonString) {
    final parsed = json.decode(jsonString)['allTags'];
    print(parsed.toString());
    return parsed.map<Tag>((json) => Tag.fromJson((json))).toList();
  }

  Widget row(item) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            item,
            style: TextStyle(color: Colors.black54),
          ),
        )
      ],
    );
  }

  AutoCompleteTextField searchTextField;

  @override
  void initState() {
    // TODO: implement initState
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var selectedCommunties = Provider.of<SelectedCommunityProvider>(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () async {
                await updateEpisode(
                    userID: widget.userID,
                    episodeId: widget.currentEpisodeId,
                    episodeName: widget.episodeTitle,
                    imageUrl: widget.episodeImage,
                    description: widget.episodeDescription,
                    podcastId: widget.currentPodcastId,
                    status: true,
                    communities: selectedCommunties.selectedCommunities);

                selectedCommunties.clearSelectedCommunities();

                print(widget.currentEpisodeId);
              },
              child: Container(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Text(
                    "Done",
                    style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: kPrimaryColor,
        title: Center(
          child: Text(
            "Select Tags",
            style: TextStyle(
                color: Colors.white,
                fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: isTagsLoading,
        color: kPrimaryColor,
        child: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              child: tags.length == 0
                  ? FadeInImage.assetNetwork(
                      placeholder: 'assets/images/startNow.png',
                      image: 'assets/images/startNow.png')
                  : ListView(
                      children: [
                        Column(
                          children: [
                            for (var v in tags)
                              ListTile(
                                onTap: () {
                                  setState(() {
                                    if (selectedTags.length < 5) {
                                      selectedTags.add(v);
                                      print(selectedTags.toString());
                                    }
                                  });
                                },
                                title: Text(
                                  v['name'],
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            width: double.infinity,
                            height: 80,
                          ),
                        )
                      ],
                    ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                  ),
                  height: 120,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 15,
                            children: [
                              for (var v in selectedTags)
                                Chip(
                                  backgroundColor: Colors.white,
                                  label: Text(
                                    v['name'],
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      selectedTags
                                          .removeAt(selectedTags.indexOf(v));
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                        Container(
                          height: SizeConfig.safeBlockVertical * 5,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: kSecondaryColor,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 0),
                                      child: TextField(
                                        controller: _controller,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3),
                                        decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText:
                                                "Enter the keyword & click the button   -->",
                                            hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3)),
                                        onChanged: (value) {
                                          setState(() {
                                            query = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                child: IconButton(
                                  icon: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    getTags(query);
                                    _controller.clear();
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Tag {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  Tag({this.id, this.name, this.createdAt, this.updatedAt});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
        id: json['id'],
        name: json['name'] as String,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String);
  }
}

class TagList {
  final List<Tag> tags;

  TagList({this.tags});

  factory TagList.fromJson(List<dynamic> parsedJson) {
    List<Tag> tags = List<Tag>();
    tags = parsedJson.map((e) => Tag.fromJson(e)).toList();

    return TagList(tags: tags);
  }
}
