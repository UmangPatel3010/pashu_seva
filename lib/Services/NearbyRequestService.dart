import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class NearbyRequestService {
  final CollectionReference requestsCollection = FirebaseFirestore.instance.collection('requests');
  final geo = GeoFlutterFire();

  Stream<List<DocumentSnapshot>> getNearbyRequests(Position position) {
    final center = geo.point(latitude: position.latitude, longitude: position.longitude);

    final collectionRef = requestsCollection.where('status', isEqualTo: 'open');

    return geo.collection(collectionRef: collectionRef)
        .within(center: center, radius: 1, field: 'position');
  }
}
