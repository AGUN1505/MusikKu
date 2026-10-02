import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musikku/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set transparent system navigation & status bar for immersive look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MusikKuApp());
}
