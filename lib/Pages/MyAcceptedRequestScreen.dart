import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pashu_seva/Services/MyAccpetedRequestService.dart';
import 'package:pashu_seva/Services/RequestService.dart';

class MyAcceptedRequestScreen extends StatefulWidget {
  const MyAcceptedRequestScreen({super.key});

  @override
  State<MyAcceptedRequestScreen> createState() => _MyAcceptedRequestScreenState();
}

class _MyAcceptedRequestScreenState extends State<MyAcceptedRequestScreen> {
  final myRequestService = MyRequestService();
  final requestService = RequestService();

  void _closeRequest(String requestId) async {
    await requestService.closeRequest(requestId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request Closed")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Accepted Requests')),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: myRequestService.getMyAcceptedRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final myRequests = snapshot.data!;

          if (myRequests.isEmpty) {
            return const Center(child: Text("You have not accepted any requests."));
          }

          // Sort logic with safe casting
          myRequests.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aStatus = aData['status'];
            final bStatus = bData['status'];

            if (aStatus == bStatus) {
              if (aStatus == 'accepted') {
                final aAcceptedAt = aData.containsKey('acceptedAt')
                    ? (aData['acceptedAt'] as Timestamp)
                    : Timestamp(0, 0);
                final bAcceptedAt = bData.containsKey('acceptedAt')
                    ? (bData['acceptedAt'] as Timestamp)
                    : Timestamp(0, 0);
                return bAcceptedAt.compareTo(aAcceptedAt);
              } else if (aStatus == 'closed') {
                final aClosedAt = aData.containsKey('closedAt')
                    ? (aData['closedAt'] as Timestamp)
                    : Timestamp(0, 0);
                final bClosedAt = bData.containsKey('closedAt')
                    ? (bData['closedAt'] as Timestamp)
                    : Timestamp(0, 0);
                return bClosedAt.compareTo(aClosedAt);
              }
            }
            if (aStatus == 'accepted') return -1;
            if (bStatus == 'accepted') return 1;
            return 0;
          });

          return ListView.builder(
            itemCount: myRequests.length,
            itemBuilder: (context, index) {
              final request = myRequests[index];
              final data = request.data() as Map<String, dynamic>;

              final imageUrl = data['imageUrl'];
              final description = data['description'] ?? "";
              final status = data['status'];

              DateTime? acceptedAt;
              DateTime? closedAt;

              if (data.containsKey('acceptedAt')) {
                acceptedAt = (data['acceptedAt'] as Timestamp).toDate();
              }
              if (data.containsKey('closedAt')) {
                closedAt = (data['closedAt'] as Timestamp).toDate();
              }

              String timeText = '';
              if (status == 'accepted' && acceptedAt != null) {
                timeText = "Accepted: ${DateFormat('dd MMM, hh:mm a').format(acceptedAt)}";
              } else if (status == 'closed' && closedAt != null) {
                timeText = "Closed: ${DateFormat('dd MMM, hh:mm a').format(closedAt)}";
              }

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
                    "Request ID: ${request.id}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(timeText),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(description, style: const TextStyle(fontSize: 15)),
                    ),
                    if (status == 'accepted')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: () => _closeRequest(request.id),
                          icon: const Icon(Icons.check),
                          label: const Text("Close Request"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (status == 'closed')
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Request Closed",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
