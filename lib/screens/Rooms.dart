import 'dart:io';

import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../CategoriesProvider.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  var prefs;

  SimpleWebSocket socket = SimpleWebSocket(
      'https://ipfs.aureal.one', '71525c0c-02e4-4aec-a2f7-b859fb19e4fa');

  void socketConnection() async {
    socket.connectToServer();
  }

  @override
  void initState() {
    // TODO: implement initState
    socketConnection();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    socket.socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    Launcher launcher = Launcher();

    Future<void> _pullRefresh() async {
      print('proceedd');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Scaffold(
              extendBody: true,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    height: MediaQuery.of(context).size.height / 5,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.height / 9,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        width: 1, color: Color(0xff3a3a3a))),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    child: Icon(Icons.library_add),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text("Sessions name"),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  showBarModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return RoomOptions();
                                      });
                                },
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height / 9,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          width: 1, color: Color(0xff3a3a3a))),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Container(
                                      child: Icon(Icons.add),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text("New Room"),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.height / 9,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        width: 1, color: Color(0xff3a3a3a))),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    child: Icon(Icons.library_add),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text("Join with Link"),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum RoomType { public, social, private }

typedef void OnMessageCallback(String tag, dynamic msg);
typedef void OnCloseCallback(int code, String reason);
typedef void OnOpenCallback();

const CLIENT_ID_EVENT = 'client-id-event';
const OFFER_EVENT = 'offer-event';
const ANSWER_EVENT = 'answer-event';
const ICE_CANDIDATE_EVENT = 'ice-candidate-event';

class SimpleWebSocket {
  String url;
  String roomId;
  IO.Socket socket;
  OnOpenCallback onOpen;
  OnMessageCallback onMessage;
  OnCloseCallback onClose;

  SimpleWebSocket(this.url, this.roomId);

  connectToServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      socket = IO.io(url);
      // await socket.connect();
      // print(socket.toString());
      // print(socket.id);
      // print(socket.io);
      await socket.emit('join_room', {
        'roomID': "51403b1f-0a18-4d86-bc8d-974028f95efe",
        'userData': {'userId': prefs.getString('userId'), 'name': 'asdasdasd'},
        'roomDetails': {
          'title': 'asdsadsa',
          'description': 'asdsada',
          'imageurl': 'asdsadasd'
        }
      });
      print(socket.id);
      // socket.onConnect((data) => print(data.toString()));
      // socket.onevent  = (SignalingState state) {}
    } catch (e) {
      print(e);
    }
  }

  // connect() async {
  //   try {
  //     socket = IO.io(url, roomId);
  //     // Dart client
  //     socket.on('connect', (_) {
  //       print('connected');
  //       onOpen();
  //     });
  //     socket.on(CLIENT_ID_EVENT, (data) {
  //       onMessage(CLIENT_ID_EVENT, data);
  //     });
  //     socket.on(OFFER_EVENT, (data) {
  //       onMessage(OFFER_EVENT, data);
  //     });
  //     socket.on(ANSWER_EVENT, (data) {
  //       onMessage(ANSWER_EVENT, data);
  //     });
  //     socket.on(ICE_CANDIDATE_EVENT, (data) {
  //       onMessage(ICE_CANDIDATE_EVENT, data);
  //     });
  //     socket.on('exception', (e) => print('Exception: $e'));
  //     socket.on('connect_error', (e) => print('Connect error: $e'));
  //     socket.on('disconnect', (e) {
  //       print('disconnect');
  //       onClose(0, e);
  //     });
  //     socket.on('fromServer', (_) => print(_));
  //   } catch (e) {
  //     this.onClose(500, e.toString());
  //   }
  // }

  send(event, data) {
    if (socket != null) {
      socket.emit(event, data);
      print('send: $event - $data');
    }
  }

  close() {
    if (socket != null) socket.close();
  }
}

class ScheduleLive extends StatefulWidget {
  @override
  _ScheduleLiveState createState() => _ScheduleLiveState();
}

class _ScheduleLiveState extends State<ScheduleLive> {
  DateTime scheduledDateTime;
  bool privateSession = false;

  bool isLoading = false;
  bool isImageLoading = false;
  final picker = ImagePicker();

  File _image;

  Dio dio = Dio();
  String displayLiveImage;
  String fullname = '';
  String bio = '';
  bool buttonState;
  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.image;
  bool loadingBuilder;
  String displayPicture;

  Future getImageFile() async {
    setState(() {
      isImageLoading = true;
    });
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.ratio16x9,
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 16 / 9,
        ));

    var optimisedImage = img.decodeImage(croppedFile.readAsBytesSync());

    var newImage = img.copyResize(optimisedImage, width: 1401);
    final directory = await getTemporaryDirectory();

    String fileName =
        '${directory.path}/OptimisedImage + ${DateTime.now()}.png';

    File('$fileName').writeAsBytesSync(img.encodePng(newImage));
    setState(() {
      if (pickedFile != null) {
        _image = File('$fileName');
      } else {
        print('No file selected');
      }
    });

    await _upload();
    setState(() {
      isImageLoading = false;
    });
  }

  void _upload() async {
    setState(() {
      isLoading = true;
    });
    setState(() {
      isImageLoading = true;
    });
    var map = Map<String, dynamic>();
//    map['duration'] = '00000';
    map['imageBlob'] =
        await MultipartFile.fromFile(_image.path); //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    var response = await dio.post("https://api.aureal.one/public/getImageUrl",
        data: formData);
    print(response.data.toString());
    setState(() {
      displayLiveImage = response.data['imageUrl']['url'];
      print(displayLiveImage);
    });
    setState(() {
      isLoading = false;
    });
    setState(() {
      isImageLoading = false;
    });
  }

  void getProviderData() {
    var categories = Provider.of<CategoriesProvider>(context, listen: false);
    categoryList = categories.categoryList;

    for (var v in categoryList) {
      setState(() {
        v['isSelected'] = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getProviderData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_outlined),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.arrow_forward_ios_outlined),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            child: getPage(),
          ),
        ),
      ),
    );
  }

  Color kArtColor = Color(0xff3a3a3a);

  Widget _everythingelse() {
    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Time"),
            ),
            SizedBox(
              height: 10,
            ),
            InkWell(
              onTap: () async {
                DateTime _time = DateTime.now();

                DateTime date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2099));
                TimeOfDay time = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());

                setState(() {
                  _time = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute);
                  scheduledDateTime = _time;
                });

                print(_time);
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xff3a3a3a))),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                          "${scheduledDateTime == null ? 'Select Time' : scheduledDateTime}")
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Private Session"),
                      SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {},
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                        ),
                      )
                    ],
                  ),
                ),
                Switch(
                    splashRadius: 10,
                    value: privateSession,
                    onChanged: (value) {
                      setState(() {
                        privateSession = !privateSession;
                      });
                    }),
                SizedBox(
                  height: 20,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Add Your Album Art"),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    InkWell(
                      onTap: () async {
                        await getImageFile();
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: displayLiveImage != null
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          gradient: LinearGradient(colors: [
                                            kArtColor,
                                            Colors.transparent
                                          ]),
                                          image: DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                  displayLiveImage)))
                                      : BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          color: kArtColor),
                                ),
                                displayLiveImage != null
                                    ? SizedBox()
                                    : Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${_titleController.text}",
                                              style: TextStyle(
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      7),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Icon(Icons.stream),
                                                Icon(Icons.edit)
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            kArtColor = Color(0xff3a3a3a);
                          });
                        },
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Color(0xff3a3a3a),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            kArtColor = Color(0xffb00b69);
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xffb00b69),
                          radius: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            kArtColor = Colors.blue;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            kArtColor = Color(0xffff715b);
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xffff715b),
                          radius: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            kArtColor = Color(0xff6825bf);
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xff6825bf),
                          radius: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            kArtColor = Color(0xff00adb5);
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xff00adb5),
                          radius: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            index = 0;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Color(0xff3a3a3a))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 7),
                            child: Center(
                                child: Text(
                              "Cancel",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 3),
                            )),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            index = 2;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Color(0xff3a3a3a)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 7),
                            child: Center(
                                child: Text(
                              "Save",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 3),
                            )),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
              ],
            )
          ],
        ),
      ],
    );
  }

  int index = 0;

  Widget getPage() {
    switch (index) {
      case 0:
        return _roomTextFields();
      case 1:
        return _everythingelse();
      case 2:
        return _selectOrAddTags();
    }
  }

  bool selected = false;
  var selectedCategory;

  List categoryList;

  Widget _selectOrAddTags() {
    // return GridView.count(
    //   shrinkWrap: true,
    //   crossAxisCount: 2,
    //   crossAxisSpacing: 1,
    //   mainAxisSpacing: 1,
    //   children: [
    //     for (var v in categories.categoryList)
    //       Padding(
    //         padding: const EdgeInsets.all(7.0),
    //         child: InkWell(
    //           onTap: () {
    //             Navigator.push(context, MaterialPageRoute(builder: (context) {
    //               return CategoryView(
    //                 categoryObject: v,
    //               );
    //             }));
    //           },
    //           child: Container(
    //             decoration: BoxDecoration(
    //                 gradient: LinearGradient(
    //                     colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: [
    //                 Padding(
    //                   padding: const EdgeInsets.all(40.0),
    //                   child: Text(
    //                     v['name'],
    //                     textScaleFactor: 0.75,
    //                     style: TextStyle(
    //                         color: Colors.white,
    //                         fontSize: SizeConfig.safeBlockHorizontal * 4),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       )
    //   ],
    // );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Select Category",
                textScaleFactor: 1.0,
                style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Wrap(
              spacing: 10,
              children: [
                for (var v in categoryList)
                  ChoiceChip(
                    label: Text("${v['name']}"),
                    selected: v['isSelected'],
                    onSelected: (value) {
                      print(v['isSelected']);
                      print(v);
                      setState(() {
                        v['isSelected'] = !v['isSelected'];
                      });
                      print(v);
                      print(v['isSelected']);
                    },
                  ),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xff3a3a3a),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text("Done"),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  TextEditingController _titleController = TextEditingController();

  Widget _roomTextFields() {
    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Topic",
                style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  // border: Border.all(color: Color(0xff3a3a3a)),
                  color: Color(0xff222222),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: _titleController,
                    maxLength: 50,
                    style: TextStyle(color: Color(0xffe8e8e8)),
                    decoration: InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Text("Description",
            //       style:
            //           TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 5)),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 10),
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: Color(0xff222222),
            //       borderRadius: BorderRadius.circular(10),
            //       // border: Border.all(color: Color(0xff3a3a3a)),
            //     ),
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 15),
            //       child: TextField(
            //         style: TextStyle(color: Color(0xffe8e8e8)),
            //         maxLines: 8,
            //         decoration: InputDecoration(border: InputBorder.none),
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      index = 1;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xff5bc3ef)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 8),
                      child: Text(
                        "Continue",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4.5),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ],
    );
  }
}

class StartRoomInstantly extends StatefulWidget {
  @override
  _StartRoomInstantlyState createState() => _StartRoomInstantlyState();
}

class _StartRoomInstantlyState extends State<StartRoomInstantly> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class RoomOptions extends StatefulWidget {
  @override
  _RoomOptionsState createState() => _RoomOptionsState();
}

class _RoomOptionsState extends State<RoomOptions> {
  RoomType roomType = RoomType.public;

  Widget _bottomOptions() {
    switch (roomType) {
      case RoomType.private:
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Only the people I choose"),
                SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                          colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Invite People"),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      case RoomType.social:
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Only the ones I follow"),
                SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                          colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FontAwesomeIcons.rocket),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Let's go"),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      case RoomType.public:
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Start a Room open to everyone"),
                SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                          colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FontAwesomeIcons.rocket),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Let's go"),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
    }
  }

  String topic;
  Widget dialogOptions() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Add a topic",
                  style:
                      TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
                  textScaleFactor: 1.0,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "eg. Hive is the Rockstar!",
                    style:
                        TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
                  ),
                ),
              ],
            ),
            TextField(),
            SizedBox(
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xff3a3a3a)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          child: Text("Cancel"))),
                ),
                SizedBox(
                  width: 10,
                ),
                InkWell(
                  child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xff3a3a3a),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        child: Text("Done"),
                      )),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      backgroundColor: kPrimaryColor,
                      child: dialogOptions(),
                    );
                  });
            },
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [Icon(Icons.add), Text("Add Topic")],
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      roomType = RoomType.public;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: roomType == RoomType.public
                            ? Colors.blue
                            : Color(0xff222222)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Icon(
                              Icons.public,
                              size: 50,
                            ),
                          ),
                          Text("Public")
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      roomType = RoomType.social;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: roomType == RoomType.social
                            ? Colors.blue
                            : Color(0xff222222)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Icon(
                              Icons.group,
                              size: 50,
                            ),
                          ),
                          Text("Social")
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      roomType = RoomType.private;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: roomType == RoomType.private
                            ? Colors.blue
                            : Color(0xff222222)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Icon(
                              Icons.lock,
                              size: 50,
                            ),
                          ),
                          Text("Private")
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _bottomOptions()
        ],
      ),
    );
  }
}
