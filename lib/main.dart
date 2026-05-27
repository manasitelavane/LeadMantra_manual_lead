import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/theme.dart';
import 'screens/launcher_screen.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash visible until LauncherScreen signals ready.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LauncherScreen(),
    );
  }
}
