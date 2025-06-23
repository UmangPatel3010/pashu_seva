import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pashu_seva/Pages/HomeScreen.dart';
import 'package:pashu_seva/Pages/LoginScreen.dart';

class AuthGate extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}