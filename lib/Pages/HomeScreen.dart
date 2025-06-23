import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pashu_seva/Pages/MyAcceptedRequestScreen.dart';
import 'package:pashu_seva/Pages/MyGeneratedRequestScreen.dart';
import 'package:pashu_seva/Pages/NearbyRequestsScreen.dart';
import 'package:pashu_seva/Pages/CreateRequestScreen.dart';
import 'package:pashu_seva/Services/UserService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool? isVolunteer;
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    UserService().saveDeviceToken();
  }

  Future<void> _loadUserProfile() async {
    final userService = UserService();
    final profile = await userService.getCurrentUserProfile();
    if (profile != null) {
      setState(() {
        isVolunteer = profile['isVolunteer'] ?? false;
        userName = profile['name'] ?? '';
        userEmail = profile['email'] ?? '';
      });
    }
  }

  Future<void> _updateVolunteerStatus(bool newValue) async {
    if (newValue) {
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Become Volunteer?"),
          content: const Text(
              "As a volunteer in Pushu Seva, you will receive animal help requests from nearby users (within 1km). You are expected to review and act on these requests to help animals in need. Only enable if you are committed."
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Agree")),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final userService = UserService();
    await userService.updateVolunteerStatus(newValue);
    setState(() {
      isVolunteer = newValue;
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Volunteer status updated")));
  }

  @override
  Widget build(BuildContext context) {
    if (isVolunteer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pushu Seva'),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildActionCard(
                    icon: Icons.camera_alt,
                    title: "Create Help Request",
                    subtitle: "Report an animal needing help",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen()));
                    },
                  ),
                  if (isVolunteer!) ...[
                    _buildActionCard(
                      icon: Icons.location_on,
                      title: "Nearby Requests",
                      subtitle: "See animals needing help near you",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyRequestsScreen()));
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.task_alt,
                      title: "My Accepted Requests",
                      subtitle: "Manage your accepted tasks",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAcceptedRequestScreen()));
                      },
                    ),
                  ],
                  _buildActionCard(
                    icon: Icons.history,
                    title: "My Generated Requests",
                    subtitle: "View your past generated requests",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyGeneratedRequestScreen()));
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const Icon(Icons.pets, size: 80, color: Colors.green),
          const SizedBox(height: 10),
          Text(
            "Welcome, $userName",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Chip(
            label: Text(isVolunteer! ? "Volunteer" : "Common User"),
            backgroundColor: isVolunteer! ? Colors.orange.shade100 : Colors.blue.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          leading: Icon(icon, size: 30, color: Colors.green),
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName ?? ''),
            accountEmail: Text(userEmail ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.green),
            ),
            decoration: const BoxDecoration(color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: const Text("Volunteer Mode"),
            trailing: Switch(
              value: isVolunteer ?? false,
              onChanged: (value) {
                _updateVolunteerStatus(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
