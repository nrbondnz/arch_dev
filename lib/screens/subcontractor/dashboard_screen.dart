import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';

import '../../widgets/summary_tile.dart';
import 'job_list_screen.dart';
import 'quote_builder_screen.dart';
import 'daily_log_screen.dart';
import 'variation_form_screen.dart';
import 'progress_claim_screen.dart';

class SubcontractorDashboardScreen extends StatelessWidget {
  const SubcontractorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SignOutButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text('Good morning, Alex', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Here\'s your current workload', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),

              // Summary tiles
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SummaryTile(
                    label: 'Active Jobs',
                    count: '4',
                    icon: Icons.work_outline,
                    color: const Color(0xFF1A56DB),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobListScreen())),
                  ),
                  SummaryTile(
                    label: 'Quotes Pending',
                    count: '2',
                    icon: Icons.description_outlined,
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  SummaryTile(
                    label: 'Variations Awaiting',
                    count: '3',
                    icon: Icons.edit_note,
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  SummaryTile(
                    label: 'Claims Outstanding',
                    count: '1',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF0E9F6E),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Quick actions
              const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _QuickActionRow(actions: [
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'New Quote',
                  color: const Color(0xFF1A56DB),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteBuilderScreen())),
                ),
                _QuickAction(
                  icon: Icons.today,
                  label: 'Log Progress',
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyLogScreen())),
                ),
                _QuickAction(
                  icon: Icons.edit,
                  label: 'Variation',
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VariationFormScreen())),
                ),
                _QuickAction(
                  icon: Icons.send,
                  label: 'New Claim',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressClaimScreen())),
                ),
              ]),

              const SizedBox(height: 28),

              // Recent activity
              const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _ActivityItem(
                title: 'Variation #V-003 approved',
                subtitle: 'Fitzroy Residential – additional brickwork',
                time: '2h ago',
                icon: Icons.check_circle,
                iconColor: Colors.green,
              ),
              _ActivityItem(
                title: 'Progress claim submitted',
                subtitle: 'North Melbourne Commercial – March 2026',
                time: 'Yesterday',
                icon: Icons.send,
                iconColor: Colors.blue,
              ),
              _ActivityItem(
                title: 'Quote requested',
                subtitle: 'Collingwood Warehouse – Stage 2 scope',
                time: '2 days ago',
                icon: Icons.description_outlined,
                iconColor: Colors.orange,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Quotes'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Claims'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const JobListScreen()));
        },
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}
