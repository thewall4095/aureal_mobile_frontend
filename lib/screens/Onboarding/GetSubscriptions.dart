import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Subscriptiongetter extends StatefulWidget {
  Subscriptiongetter();

  @override
  State<Subscriptiongetter> createState() => _SubscriptiongetterState();
}

class _SubscriptiongetterState extends State<Subscriptiongetter> {
  Widget pageGenerator(int index) {
    switch (index) {
      case 0:
        return SelectCategories();
        break;
      case 1:
        return SelectPodcasts();
    }
  }

  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        title: Text("Lets get your subscriptions"),
      ),
      body: Stack(children: [
        pageGenerator(counter),
        Align(
          alignment: Alignment.bottomCenter,
          child: InkWell(
            onTap: () {
              setState(() {
                counter++;
              });
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(gradient: kGradient),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Continue",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        )
      ]),
    );
  }
}

class SelectCategories extends StatefulWidget {
  const SelectCategories();

  @override
  State<SelectCategories> createState() => _SelectCategoriesState();
}

class _SelectCategoriesState extends State<SelectCategories> {
  SharedPreferences prefs;

  Dio dio = Dio();

  CancelToken _cancel = CancelToken();

  Future getUserCategories() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getCategory?user_id=${prefs.getString('userId')}";
    print(url);

    try {
      var response = await dio.get(url, cancelToken: _cancel);

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future sendCategories(var categoryObject) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/addUserCategory';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    if (categoryObject['isselected'] == true) {
      map['operation'] = 'remove';
    }

    map['category_ids'] = categoryObject['id'];
    print(map);

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    return response;
  }

  Future myFuture;

  void init() {
    myFuture = getUserCategories();
  }

  List _icons = [
    LineIcons.palette,
    LineIcons.briefcase,
    LineIcons.laughFaceWithBeamingEyes,
    LineIcons.fruitApple,
    LineIcons.cloudWithAChanceOfMeatball,
    LineIcons.businessTime,
    LineIcons.hourglass,
    LineIcons.swimmingPool,
    LineIcons.baby,
    LineIcons.beer,
    LineIcons.music,
    LineIcons.newspaper,
    LineIcons.twitter,
    LineIcons.atom,
    LineIcons.globe,
    LineIcons.footballBall,
    LineIcons.alternateGithub,
    LineIcons.dungeon,
    LineIcons.television
  ];

  postreq.Interceptor intercept = postreq.Interceptor();

  @override
  void initState() {
    // TODO: implement initState
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: myFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemBuilder: (context, int index) {
                if (index == snapshot.data.length) {
                  return SizedBox(
                    height: 100,
                  );
                } else {
                  return ListTile(
                    onTap: () {
                      sendCategories(snapshot.data[index]).then((value) {
                        setState(() {
                          snapshot.data[index]['isselected'] =
                              !snapshot.data[index]['isselected'];
                        });
                      });
                    },
                    selectedTileColor: Colors.blue,
                    textColor: Colors.white,
                    selected: snapshot.data[index]['isselected'],
                    title: Text("${snapshot.data[index]['name']}"),
                  );
                }
              },
              itemCount: snapshot.data.length + 1,
            );
          } else {
            return Container();
          }
        });
  }
}

class SelectPodcasts extends StatefulWidget {
  const SelectPodcasts();

  @override
  State<SelectPodcasts> createState() => _SelectPodcastsState();
}

class _SelectPodcastsState extends State<SelectPodcasts> {
  SharedPreferences prefs;

  Dio dio = Dio();
  CancelToken _cancel = CancelToken();
  List selectedCategories = [];
  Future getCategories() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getCategory?user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        for (var v in response.data['data']) {
          if (v['isselected'] == true) {
            selectedCategories.add(v);
          }
          return selectedCategories;
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future getPodcasts(categoryObject) async {
    String url =
        "https://api.aureal.one/public/explore?category_id=${categoryObject['id']}&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);

      if (response.statusCode == 200) {
      } else {
        print(response.statusCode);
      }
    } catch (e) {}
  }

  @override
  void initState() {
    // TODO: implement initState
    getCategories().then((value) {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
