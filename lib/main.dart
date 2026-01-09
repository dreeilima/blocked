import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const BlockedApp());
}

class BlockedApp extends StatelessWidget {
  const BlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blocked',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF2C3E50),
      ),
      home: const GameScreen(),
    );
  }
}
