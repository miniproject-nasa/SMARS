import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final String userType;

  const LoginScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$userType Login")),
      body: Center(child: Text("Login screen for $userType")),
    );
  }
}
