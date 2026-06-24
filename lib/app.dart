import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/home/screens/home_screen.dart';

class OrbApp extends StatelessWidget {
  const OrbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orb',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
