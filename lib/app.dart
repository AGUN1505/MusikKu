import 'package:flutter/material.dart';
import 'package:musikku/core/theme/app_theme.dart';
import 'package:musikku/features/home/presentation/screens/home_screen.dart';

class MusikKuApp extends StatelessWidget {
  const MusikKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusikKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
