import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pashu_seva/Pages/LoginScreen.dart';
import 'package:pashu_seva/Services/AuthService.dart';
import 'package:pashu_seva/Services/UserService.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isPasswordVisible = false;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;

  void signUp() async {
    setState(() {
      _isLoading = true;
    });

    User? user = await _authService.signUpWithEmailPassword(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (user != null) {
      // Create user profile with isVolunteer = false
      await _userService.createUserProfile(user, nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Failed")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Icon(Icons.pets, size: 100, color: Color(0xFF4CAF50)),
              const SizedBox(height: 20),
              const Text(
                "Join Pushu Seva",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C)),
              ),
              const SizedBox(height: 40),

              // Name field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.person, color: Color(0xFF4CAF50)),
                  labelText: 'Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Email field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.email,
                    color: Color(0xFF4CAF50),
                  ),
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password field
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: Color(0xFF4CAF50),
                  ),
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  focusColor: Colors.red,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Signup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: const Color(0xFFFFA366),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'I already have have an account? Sign In',
                  style: TextStyle(color: Color(0xFF2D6A4F)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
