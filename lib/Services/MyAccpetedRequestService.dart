import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestService {
  final CollectionReference requestsCollection = FirebaseFirestore.instance.collection('requests');

  Stream<List<DocumentSnapshot>> getMyAcceptedRequests() {
    User? volunteer = FirebaseAuth.instance.currentUser;
    if (volunteer == null) {
      return Stream.value([]);
    }

    return requestsCollection
        .where('acceptedBy', isEqualTo: volunteer.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}
