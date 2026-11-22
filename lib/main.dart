import 'package:flutter/material.dart';
import 'package:skinsense/screens/profile.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Scaffold(body: ProfileScreen(),)
    );
  }
}

