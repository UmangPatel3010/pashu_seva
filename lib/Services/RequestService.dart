import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:http/http.dart' as http;

class RequestService {
  final CollectionReference requestsCollection = FirebaseFirestore.instance.collection('requests');
  final geo = GeoFlutterFire();

  Future<void> createRequest(
      String imageUrl,
      double latitude,
      double longitude, {
        required String description,
      }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final position = geo.point(latitude: latitude, longitude: longitude);

    await requestsCollection.add({
      'userId': user.uid,
      'imageUrl': imageUrl,
      'description': description,
      'position': position.data,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }
  Future<void> acceptRequest(String requestId) async {
    User? volunteer = FirebaseAuth.instance.currentUser;
    if (volunteer == null) return;

    await requestsCollection.doc(requestId).update({
      'status': 'accepted',
      'acceptedBy': volunteer.uid,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeRequest(String requestId) async {
    await requestsCollection.doc(requestId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPushNotificationToVolunteers(String title,String message) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isVolunteer', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      String? token = doc['fcmToken'];
      if (token != null && doc['uid'] != FirebaseAuth.instance.currentUser?.uid) {
        await sendFCMUsingBackend(token,title, message);
      }
    }
  }

  Future<void> sendFCMUsingBackend(String token, String title, String body) async {
    final url = Uri.parse('https://pashu-seva-notification-api.onrender.com/send-notification');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'title': title,
        'body': body,
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

// Future<void> sendNotificationToOthers(String token, String title, String body) async {
//   try {
//     final callable =
//     FirebaseFunctions.instance.httpsCallable('sendNotificationToOthers');
//     final response = await callable.call({
//       'title': title,
//       'body': body,
//       'token': token
//     });
//
//     print('Notification sent: ${response.data}');
//   } catch (e) {
//     print('Error sending notification: $e');
//   }
// }
}
