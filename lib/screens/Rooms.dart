import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
    // prefs = await SharedPreferences.getInstance();
    // var userData = {'name': "Shubham", 'userId': prefs.getString('userId')};
    // IO.Socket socket = IO.io('https://ipfs.aureal.one');
    // socket.onConnect((_) {
    //   socket.emit(
    //       'join_room', '71525c0c-02e4-4aec-a2f7-b859fb19e4fa', userData);
    // });
    // IO.Socket socket = IO.io('https://ipfs.aureal.one');
    // socket.onConnect((_) {
    //   print('connect');
    //   socket.emit('join_room', '71525c0c-02e4-4aec-a2f7-b859fb19e4fa');
    // });
    // socket.on('event', (data) => print(data));
    // socket.onDisconnect((_) => print('disconnect'));
    // socket.on('fromServer', (_) => print(_));
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
                                        return ScheduleLive();
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
                                child: Text("Schedule New"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          "Schedule your live Session",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text("Title"),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xff3a3a3a)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              decoration:
                                  InputDecoration(border: InputBorder.none),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text("Description"),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xff3a3a3a)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              maxLines: 8,
                              decoration:
                                  InputDecoration(border: InputBorder.none),
                            ),
                          ),
                        ),
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
                            _time = DateTime(date.year, date.month, date.day,
                                time.hour, time.minute);
                            scheduledDateTime = _time;
                          });

                          print(_time);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Color(0xff3a3a3a))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
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
                            height: 30,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Invite your co-hosts"),
                              ListTile(
                                leading: Container(
                                  height: 40,
                                  width: 40,
                                  child: Icon(Icons.add),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: Color(0xff3a3a3a))),
                                ),
                                title: Text("Add People"),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Your Album Art"),
                              SizedBox(
                                height: 20,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    color: Color(0xff3a3a3a),
                                    child: Icon(Icons.add),
                                  ),
                                ),
                              )
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
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Color(0xff3a3a3a))),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 7),
                                      child: Center(
                                          child: Text(
                                        "Cancel",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3),
                                      )),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                InkWell(
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
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3),
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
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
