import 'package:flutter/material.dart';

import '../core/app_bar.dart';
import '../core/app_dialog.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/lead_service.dart';
import 'delete_account_screen.dart';
import 'leads_screen.dart';
import 'new_lead_screen.dart';
import 'total_leads_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ── Helpers ─────────────────────────────────────────────────────────────

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 21) return 'Good Evening';
    return 'Good Night';
  }

  String get _userName {
    final u = AuthService.instance.user;
    if (u == null) return '';
    return (u['name'] as String? ?? u['email'] as String? ?? '').trim();
  }

  // ── Navigation / dialogs ─────────────────────────────────────────────────

  void _showPrivacyPolicy(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
      );

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.clearSession();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmLogout(BuildContext context) => AppDialog.show(
        context: context,
        icon: Icons.logout_rounded,
        title: 'Logout',
        message: 'Are you sure you want to logout?',
        confirmLabel: 'Logout',
        onConfirm: () => _logout(context),
      );

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(
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
                    MaterialPageRoute(
                        builder: (_) => DeleteAccountScreen(userId: userId)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Greeting banner ──────────────────────────────────
              _GreetingCard(greeting: _greeting, userName: _userName),

              const SizedBox(height: 16),

              // ── 2. Lead stats ───────────────────────────────────────
              const _LeadStatsCard(),

              const SizedBox(height: 20),

              // ── 3. New Lead button ──────────────────────────────────
              _NewLeadButton(onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewLeadScreen()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting banner ──────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.greeting, required this.userName});
  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (userName.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    userName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                const Text(
                  'Never Miss a Lead Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'WhatsApp-First CRM · Built for India',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Logo box
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'assets/images/logo_3 1.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.business_rounded,
                color: AppTheme.primary,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lead stats card ──────────────────────────────────────────────────────────

class _LeadStatsCard extends StatefulWidget {
  const _LeadStatsCard();

  @override
  State<_LeadStatsCard> createState() => _LeadStatsCardState();
}

class _LeadStatsCardState extends State<_LeadStatsCard> {
  @override
  void initState() {
    super.initState();
    // Fetch backend total in the background so the count reflects all leads
    LeadService.instance.fetchLeads(page: 1, perPage: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'My Leads',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stat row
          ListenableBuilder(
            listenable: LeadService.instance,
            builder: (context, _) {
              final svc = LeadService.instance;
              final totalValue = svc.remoteTotal?.toString() ?? '--';
              return IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Total Leads',
                        value: totalValue,
                        iconData: Icons.people_alt_rounded,
                        iconColor: AppTheme.primary,
                        valueColor: AppTheme.primary,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const TotalLeadsScreen())),
                      ),
                    ),
                    VerticalDivider(
                      color: Colors.grey.shade200,
                      thickness: 1,
                      width: 1,
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Uploaded',
                        value: '${svc.uploadedLeads.length}',
                        iconData: Icons.upload_rounded,
                        iconColor: AppTheme.accent,
                        valueColor: AppTheme.accent,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                const LeadsScreen(type: LeadType.uploaded))),
                      ),
                    ),
                    VerticalDivider(
                      color: Colors.grey.shade200,
                      thickness: 1,
                      width: 1,
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Offline',
                        value: '${svc.offlineLeads.length}',
                        iconData: Icons.wifi_off_rounded,
                        iconColor: const Color(0xFF78909C),
                        valueColor: const Color(0xFF78909C),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                const LeadsScreen(type: LeadType.offline))),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.iconData,
    required this.iconColor,
    required this.valueColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData iconData;
  final Color iconColor;
  final Color valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ── New Lead button ──────────────────────────────────────────────────────────

class _NewLeadButton extends StatelessWidget {
  const _NewLeadButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, Color(0xFFEF6C00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: const Text(
            'New Lead',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
