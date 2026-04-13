import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/domain.dart';
import '../services/auth_service.dart';
import 'admin/dashboard_screen.dart';
import 'backend_seeder_screen.dart';
import 'site_manager/dashboard_screen.dart';

/// Entry point after Cognito sign-in.
/// Checks for a Cognito group and auto-routes, or shows the role picker.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _autoRoute();
  }

  Future<void> _autoRoute() async {
    try {
      final group = await AuthService.getCurrentUserGroup();
      if (!mounted) return;

      // Map Cognito groups to the two internal roles.
      UserRole? role;
      if (group == 'admin-manager' || group == 'sub-contractor' || group == 'admin') {
        role = UserRole.adminManager;
      } else if (group == 'site-manager') {
        role = UserRole.siteManager;
      }

      if (role != null) {
        _navigateToRole(role);
        return;
      }
    } on Exception catch (e) {
      safePrint('Could not auto-route by group: $e');
    }

    if (mounted) setState(() => _checking = false);
  }

  void _navigateToRole(UserRole role) {
    if (role == UserRole.adminManager) {
      AppState().switchToAdmin();
    } else {
      AppState().switchToSiteManager();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => role == UserRole.adminManager
            ? const AdminDashboardScreen()
            : const SiteManagerDashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARCH'),
        centerTitle: true,
        actions: [const SignOutButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Logo / branding
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business, size: 48, color: Color(0xFF1A56DB)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Who are you?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Select your role to continue',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _RoleTile(
                icon: Icons.business_center_outlined,
                title: 'Admin / Manager',
                subtitle: 'Manage jobs, contracts, billing and variations',
                color: const Color(0xFF1A56DB),
                onTap: () => _navigateToRole(UserRole.adminManager),
              ),
              const SizedBox(height: 16),
              _RoleTile(
                icon: Icons.construction_outlined,
                title: 'Site Manager',
                subtitle: 'View work packages, submit daily logs, complete tasks',
                color: const Color(0xFF0E9F6E),
                onTap: () => _navigateToRole(UserRole.siteManager),
              ),
              const Spacer(),
              // Dev tool: seed backend with canonical test data
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const BackendSeederScreen()),
                ),
                icon: const Icon(Icons.storage_outlined, size: 16),
                label: const Text('Seed Backend Test Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black45,
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: color.withValues(alpha: 0.07),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
