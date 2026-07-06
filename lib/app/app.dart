import 'package:flutter/material.dart';

import '../presentation/screens/home_screen.dart';
import 'app_theme.dart';

class SpotSakuApp extends StatelessWidget {
  const SpotSakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SpotSaku",

      theme: AppTheme.lightTheme,

      home: const HomeScreen(),
    );
  }
}