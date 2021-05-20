import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:flutter/material.dart';
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
        return Scaffold(
          body: Container(),
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
