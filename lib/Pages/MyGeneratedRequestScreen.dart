import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pashu_seva/Pages/FullImageView.dart';
import 'package:pashu_seva/Services/MyGeneratedRequestService.dart';

class MyGeneratedRequestScreen extends StatefulWidget {
  const MyGeneratedRequestScreen({super.key});

  @override
  State<MyGeneratedRequestScreen> createState() =>
      _MyGeneratedRequestScreenState();
}

class _MyGeneratedRequestScreenState extends State<MyGeneratedRequestScreen> {
  final historyService = UserRequestHistoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Request History')),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: historyService.getMyRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return const Center(child: Text("No requests found."));
          }

          // Sort by timestamp descending
          // requests.sort((a, b) {
          //   final aData = a.data() as Map<String, dynamic>;
          //   final bData = b.data() as Map<String, dynamic>;
          //   final aTimestamp = aData['timestamp'] as Timestamp? ?? Timestamp(0, 0);
          //   final bTimestamp = bData['timestamp'] as Timestamp? ?? Timestamp(0, 0);
          //   return bTimestamp.compareTo(aTimestamp);
          // });

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;

              final imageUrl = data['imageUrl'];
              final status = data['status'];
              final description =
                  data['description'] ?? "No description provided.";
              final timestamp = data['timestamp'] as Timestamp?;

              String formattedTime = "N/A";
              if (timestamp != null) {
                formattedTime = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(timestamp.toDate());
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
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullImageView(imageUrl: imageUrl),
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
                    "Status: ${status.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Created: $formattedTime"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(description,
                          style: const TextStyle(fontSize: 15)),
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
