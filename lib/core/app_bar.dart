import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Shared app bar used on every screen.
///
/// - Omit [title] on main screens → logo is centred.
/// - Pass [title] on sub-screens  → styled text title.
/// - Pass [actions] for icon / menu buttons on the right.
/// - Set [automaticallyImplyLeading] to false on root screens (login, etc.).
class LeadMantraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LeadMantraAppBar({
    super.key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  /// kToolbarHeight (56) + 3 px accent stripe.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 3);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.appBarBg,
      foregroundColor: AppTheme.appBarFg,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                color: AppTheme.appBarFg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            )
          : Image.asset(
              'assets/images/logo_2 1.png',
              height: 55,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text(
                'LeadMantra',
                style: TextStyle(
                  color: AppTheme.appBarFg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(color: AppTheme.accent, height: 3),
      ),
    );
  }
}
