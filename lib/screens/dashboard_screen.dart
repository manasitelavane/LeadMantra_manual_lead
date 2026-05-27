import 'package:flutter/material.dart';
import '../core/app_bar.dart';
import '../core/app_dialog.dart';
import '../services/auth_service.dart';
import 'delete_account_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('This action will delete your account. Do you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete account flow not implemented yet.')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmLogout(BuildContext context) {
    AppDialog.show(
      context: context,
      icon: Icons.logout_rounded,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      onConfirm: () => _logout(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LeadMantraAppBar(
        title: 'Dashboard',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'privacy') {
                _showPrivacyPolicy(context);
              } else if (value == 'logout') {
                _confirmLogout(context);
              } else if (value == 'delete') {
                final userId = AuthService.instance.currentUserId;
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DeleteAccountScreen(userId: userId)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to determine user ID.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'privacy', child: Text('Privacy Policy')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
              PopupMenuItem(value: 'delete', child: Text('Delete Account')),
            ],
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to the dashboard',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
