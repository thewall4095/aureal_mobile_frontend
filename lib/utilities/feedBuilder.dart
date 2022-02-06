
import 'dart:math';
import 'package:auditory/screens/DiscoverPage.dart';
import 'package:auditory/screens/FollowingPage.dart';
import 'package:auditory/screens/Profiles/CategoryView.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../PlayerState.dart';
import 'SizeConfig.dart';

Widget _feedBuilder(BuildContext context, var data){

  SharedPreferences prefs;
  CancelToken _cancel = CancelToken();

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio(

    );
    prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";

    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }

  }

  var episodeObject = Provider.of<PlayerChange>(context);
  var currentlyPlaying = Provider.of<PlayerChange>(context);

  List colors = [Colors.red, Colors.green, Colors.yellow];
  Random random = Random();

  switch(data['type']){
    case 'podcast':
      return PodcastWidget(data: data);
      break;
    case 'episode':
      return EpisodeWidget(data: data);
      break;
    case "playlist":
      return PlaylistWidget(data: data);
      break;
    case 'snippet':
      return SnippetWidget(data: data);
      break;
    case 'user':
      return FutureBuilder(
        future: generalisedApiCall(data['api']),
        builder: (context, snapshot){
          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text("${data['name']}", style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.bold
                  )),
                ),
                Text("${snapshot.data}"),
              ],
            ),
          );
        },
      );
      break;
    case 'featured':
      return FeaturedBuilder(data: data);
      break;
    case 'category':
      return FutureBuilder(
        future: generalisedApiCall(data['api']),
        builder: (context, snapshot){
          if(snapshot.hasData){
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text("${data['name']}",style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.bold
                )),),
                Container(
                  height:
                  MediaQuery.of(context).size.height / 2.8,
                  child: GridView.builder(
                    itemCount: snapshot.data.length,
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 0,
                        childAspectRatio: 1 / 4),
                    itemBuilder: (context, int index){
                      // return Container(child: Text("${snapshot.data[index]['name']}"),);
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border(left: BorderSide(width: 3,color: Colors.primaries[index])),
                              color: Color(0xff222222)
                          ),
                          child: Center(
                            child: ListTile(
                              onTap: (){
                                Navigator.push(context, CupertinoPageRoute(builder: (context){
                                  return CategoryView(categoryObject: snapshot.data[index],);
                                }));
                              },

                              title: Text("${snapshot.data[index]['name']}", style: TextStyle(fontWeight: FontWeight.bold),),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }else{
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text("${data['name']}",style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.bold
                )),),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height:
                    MediaQuery.of(context).size.height / 2.8,
                    width: double.infinity,
                    color: Color(0xff222222),
                  ),
                ),
              ],
            );
          }

        },
      );
      break;
    default:
      return Container();
      break;
  }
}