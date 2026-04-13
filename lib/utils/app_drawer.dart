import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/domain.dart';

// Forward declarations to avoid circular imports — screens imported lazily.
// We use route replacement so this is fine with late binding.
Widget Function() _adminDashboardBuilder = () => throw UnimplementedError();
Widget Function() _siteManagerDashboardBuilder = () =>
    throw UnimplementedError();

/// Call once from main or before first route to register dashboard builders.
void registerDrawerBuilders({
  required Widget Function() adminDashboard,
  required Widget Function() siteManagerDashboard,
}) {
  _adminDashboardBuilder = adminDashboard;
  _siteManagerDashboardBuilder = siteManagerDashboard;
}

/// Shared app drawer shown in every new-architecture screen.
/// Provides role switching and branding.
Drawer buildArchDrawer(BuildContext context) {
  final state = AppState();
  return Drawer(
    child: Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Color(0xFF1A56DB)),
          margin: EdgeInsets.zero,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  state.currentUserName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _roleLabel(state.currentRole),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'SWITCH ROLE',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.8),
          ),
        ),
        _RoleTile(
          role: UserRole.adminManager,
          label: 'Admin / Manager',
          subtitle: 'Jobs, contracts, billing',
          icon: Icons.business_center_outlined,
        ),
        _RoleTile(
          role: UserRole.siteManager,
          label: 'Site Manager',
          subtitle: 'Work packages, daily logs',
          icon: Icons.construction_outlined,
        ),
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.info_outline, size: 20),
          title: const Text('About', style: TextStyle(fontSize: 14)),
          onTap: () {
            Navigator.pop(context);
            showAboutDialog(
              context: context,
              applicationName: 'ARCH',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Sub-contractor Management System',
            );
          },
        ),
        const Spacer(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, size: 20, color: Colors.red),
          title: const Text('Sign out',
              style: TextStyle(fontSize: 14, color: Colors.red)),
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _RoleTile extends StatelessWidget {
  final UserRole role;
  final String label;
  final String subtitle;
  final IconData icon;

  const _RoleTile({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final isActive = state.currentRole == role;
    const blue = Color(0xFF1A56DB);

    return ListTile(
      leading: Icon(icon, color: isActive ? blue : Colors.grey[600], size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? blue : null,
          fontSize: 14,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing:
          isActive ? const Icon(Icons.check_circle, color: blue, size: 18) : null,
      onTap: () {
        if (isActive) {
          Navigator.pop(context);
          return;
        }
        Navigator.pop(context);
        if (role == UserRole.adminManager) {
          state.switchToAdmin();
        } else {
          state.switchToSiteManager();
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => role == UserRole.adminManager
                ? _adminDashboardBuilder()
                : _siteManagerDashboardBuilder(),
          ),
          (route) => false,
        );
      },
    );
  }
}

String _roleLabel(UserRole r) => switch (r) {
      UserRole.adminManager => 'Admin / Manager',
      UserRole.siteManager => 'Site Manager',
    };
