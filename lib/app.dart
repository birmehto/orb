import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/home/screens/home_screen.dart';

class LayApp extends StatelessWidget {
  const LayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
