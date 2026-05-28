import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../services/auth_service.dart';
import '../services/lead_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'policy_agreement_screen.dart';

/// Invisible routing screen shown while the native splash is still on top.
/// Initialises [AuthService], then removes the splash and navigates.
class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AuthService.instance.initialize();
    await LeadService.instance.initialize();
    // Dismiss the native splash now that we know where to navigate.
    FlutterNativeSplash.remove();
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = AuthService.instance;

    final Widget next;
    if (!auth.policyAccepted) {
      next = const PolicyAgreementScreen();
    } else if (auth.isLoggedIn) {
      next = const DashboardScreen();
    } else {
      next = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    // White background matches the native splash — no visual flash on remove.
    return const Scaffold(backgroundColor: Colors.white);
  }
}
