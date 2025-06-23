import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRequestHistoryService {
  final CollectionReference requestsCollection = FirebaseFirestore.instance.collection('requests');

  Stream<List<DocumentSnapshot>> getMyRequests() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return requestsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}
