import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:pashu_seva/Pages/FullImageView.dart';
import 'package:pashu_seva/Services/LocationService.dart';
import 'package:pashu_seva/Services/NearbyRequestService.dart';
import 'package:pashu_seva/Services/RequestService.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyRequestsScreen extends StatefulWidget {
  const NearbyRequestsScreen({super.key});

  @override
  State<NearbyRequestsScreen> createState() => _NearbyRequestsScreenState();
}

class _NearbyRequestsScreenState extends State<NearbyRequestsScreen> {
  Position? _currentPosition;
  Stream<List<DocumentSnapshot>>? _nearbyStream;
  String timeFilter = "Last 15 Minutes";
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _checkLocationAndLoad();
  }

  Future<void> _checkLocationAndLoad() async {
    setState(() => _locationDenied = false);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Location().requestService();
      if (!serviceEnabled) {
        setState(() {
          _locationDenied = true;
          _currentPosition = null;
          _nearbyStream = null;
        });
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _locationDenied = true;
        _currentPosition = null;
        _nearbyStream = null;
      });
      return;
    }

    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();

    _loadNearbyRequests(position);
  }

  void _loadNearbyRequests(Position position) {
    final nearbyRequestService = NearbyRequestService();
    final stream = nearbyRequestService.getNearbyRequests(position);
    setState(() {
      _currentPosition = position;
      _nearbyStream = stream;
    });
  }

  void _acceptRequest(String requestId, double lat, double lng) async {
    final requestService = RequestService();
    await requestService.acceptRequest(requestId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Request Accepted")));
    _showMapDialog(lat, lng);
  }

  void _showMapDialog(double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Navigate to Request"),
        content: const Text(
            "Would you like to open this request location in Google Maps?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchMap(lat, lng);
            },
            child: const Text("Open Maps"),
          ),
        ],
      ),
    );
  }

  void _launchMap(double latitude, double longitude) async {
    try {
      final geoUrl =
          Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
      bool launched =
          await launchUrl(geoUrl, mode: LaunchMode.externalApplication);

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps")),
        );
      }
    } on PlatformException catch (e) {
      print('PlatformException: ${e.message}');
    } on FormatException catch (e) {
      print('FormatException: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  DateTime _getMinTimestamp() {
    return DateTime.now().subtract(const Duration(minutes: 30));
  }

  @override
  Widget build(BuildContext context) {
    if (_locationDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Requests')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Location permission required to view requests.\nPlease allow it to proceed.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _checkLocationAndLoad,
                icon: const Icon(Icons.location_on),
                label: const Text("Retry Permission"),
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyStream == null || _currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Requests')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _nearbyStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!.where((doc) {
                  final status = doc['status'];
                  final timestamp = (doc['timestamp'] as Timestamp).toDate();

                  final isExpired = status == 'open' &&
                      timestamp.isBefore(
                          DateTime.now().subtract(const Duration(minutes: 30)));

                  if (isExpired) {
                    FirebaseFirestore.instance
                        .collection('requests')
                        .doc(doc.id)
                        .update({
                      'status': 'expired',
                    });
                    return false; // Don’t show expired request
                  }

                  return status ==
                      'open'; // Only show non-expired open requests
                }).toList();

                if (requests.isEmpty) {
                  return const Center(
                      child: Text(
                          "No open requests found in the last 30 minutes."));
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final imageUrl = request['imageUrl'];
                    final description = request['description'] ?? "";
                    final timestamp =
                        (request['timestamp'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: ExpansionTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FullImageView(imageUrl: imageUrl),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 60,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),
                        title: Text(
                          DateFormat('dd MMM, hh:mm a').format(timestamp),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text("Tap to view details"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(description,
                                style: const TextStyle(fontSize: 15)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptRequest(
                                request.id,
                                request['position']['geopoint'].latitude,
                                request['position']['geopoint'].longitude,
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Accept Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
