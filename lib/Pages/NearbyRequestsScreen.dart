import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pashu_seva/Services/LocationService.dart';
import 'package:pashu_seva/Services/NearbyRequestService.dart';
import 'package:pashu_seva/Services/RequestService.dart';

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

  final List<String> timeOptions = [
    "Last 15 Minutes",
    "Last 30 Minutes",
    "Last 1 Hour",
    "Last 24 Hours",
    "All"
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationAndLoad();
  }

  Future<void> _checkLocationAndLoad() async {
    setState(() => _locationDenied = false);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationDenied = true;
        _currentPosition = null;
        _nearbyStream = null;
      });
      return;
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

  void _acceptRequest(String requestId) async {
    final requestService = RequestService();
    await requestService.acceptRequest(requestId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Request Accepted")));
  }

  DateTime _getMinTimestamp() {
    final now = DateTime.now();
    switch (timeFilter) {
      case "Last 15 Minutes":
        return now.subtract(const Duration(minutes: 15));
      case "Last 30 Minutes":
        return now.subtract(const Duration(minutes: 30));
      case "Last 1 Hour":
        return now.subtract(const Duration(hours: 1));
      case "Last 24 Hours":
        return now.subtract(const Duration(hours: 24));
      default:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: timeFilter,
                  items: timeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      timeFilter = newValue!;
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _nearbyStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!
                    .where((doc) =>
                doc['status'] == 'open' &&
                    (doc['timestamp'] as Timestamp)
                        .toDate()
                        .isAfter(_getMinTimestamp()))
                    .toList()
                  ..sort((a, b) => (b['timestamp'] as Timestamp)
                      .compareTo(a['timestamp'] as Timestamp));

                if (requests.isEmpty) {
                  return const Center(child: Text("No open requests found in this time window"));
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final imageUrl = request['imageUrl'];
                    final description = request['description'] ?? "";
                    final timestamp = (request['timestamp'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                        ),
                        title: Text(
                          DateFormat('dd MMM, hh:mm a').format(timestamp),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text("Tap to view details"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(description, style: const TextStyle(fontSize: 15)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptRequest(request.id),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Accept Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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
          SizedBox(height: 20,)
        ],
      ),
    );
  }
}
