
// import 'package:flutter/material.dart';
//
// class DatabaseService {
//   final String uid;
//   DatabaseService({this.uid});
//
//   //Collection Reference
//   final CollectionReference userDetails =
//       Firestore.instance.collection('userDetails');
//
//   Future updateUserData(
//     String username,
//     DateTime date,
//   ) async {
//     return await userDetails.document(uid).setData({
//       'username': username,
//       'dateOfBirth': date,
//     });
//   }
// }
