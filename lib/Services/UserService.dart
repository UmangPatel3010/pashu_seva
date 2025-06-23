import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  // Create new user document
  Future<void> createUserProfile(User user, String name, {bool isVolunteer=false}) async {
    await usersCollection.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'isVolunteer': isVolunteer,
      'location': null,  // location will be set later
    });
  }

  // Get user profile
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot snapshot = await usersCollection.doc(user.uid).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> updateVolunteerStatus(bool isVolunteer) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await usersCollection.doc(user.uid).update({'isVolunteer': isVolunteer});
    }
  }

  Future<void> saveDeviceToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;


    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

    String? token = await firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }

}
