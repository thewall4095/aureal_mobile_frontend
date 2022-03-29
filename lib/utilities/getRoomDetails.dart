import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future getRoomDetails(var roomId) async {
  Dio dio = Dio();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = "https://api.aureal.one/public/getRoomDetails";

  var map = Map<String, dynamic>();
  map['roomid'] = roomId;

  FormData formData = FormData.fromMap(map);

  try {
    var response = await dio.post(url, data: formData);
    print(response.data);
    return response.data['data'];
  } catch (e) {
    print(e);
  }
}
