import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/router.dart';

class OrbApp extends StatelessWidget {
  const OrbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Orb',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
