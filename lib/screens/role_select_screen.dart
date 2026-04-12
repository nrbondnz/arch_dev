import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'subcontractor/dashboard_screen.dart';
import 'contractor/dashboard_screen.dart';

/// After sign-in, checks for a Cognito group assignment and routes automatically.
/// If no group is assigned (common during dev), shows the role picker.
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

      Widget? destination;
      if (group == 'sub-contractor') {
        destination = const SubcontractorDashboardScreen();
      } else if (group == 'main-contractor') {
        destination = const ContractorDashboardScreen();
      } else if (group == 'qs') {
        destination = const ContractorDashboardScreen(isQS: true);
      }

      if (destination != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => destination!),
        );
        return;
      }
    } on Exception catch (e) {
      safePrint('Could not auto-route by group: $e');
    }

    // No group found — show manual picker
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARCH'),
        actions: [const SignOutButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Who are you?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to continue',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _RoleTile(
                icon: Icons.construction,
                title: 'Sub-contractor',
                subtitle: 'Submit quotes, log progress, raise variations & claims',
                color: const Color(0xFF1A56DB),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SubcontractorDashboardScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _RoleTile(
                icon: Icons.domain,
                title: 'Main Contractor',
                subtitle: 'Review & approve quotes, variations and progress claims',
                color: const Color(0xFF0E9F6E),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ContractorDashboardScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _RoleTile(
                icon: Icons.calculate_outlined,
                title: 'Quantity Surveyor',
                subtitle: 'Assess claims, manage valuations and retention',
                color: const Color(0xFFE3A008),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ContractorDashboardScreen(isQS: true)),
                ),
              ),
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
      color: color.withOpacity(0.07),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
