import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/ModelProvider.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/quote_service.dart';
import '../../widgets/summary_tile.dart';
import 'job_list_screen.dart';
import 'quote_builder_screen.dart';
import 'daily_log_screen.dart';
import 'variation_form_screen.dart';
import 'progress_claim_screen.dart';

class SubcontractorDashboardScreen extends StatefulWidget {
  const SubcontractorDashboardScreen({super.key});

  @override
  State<SubcontractorDashboardScreen> createState() => _SubcontractorDashboardScreenState();
}

class _SubcontractorDashboardScreenState extends State<SubcontractorDashboardScreen> {
  String _userName = '';
  int _jobCount = 0;
  int _pendingQuotes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        AuthService.getCurrentUserDisplayName(),
        JobService.listJobs(),
        QuoteService.listQuotesByStatus(QuoteStatus.Submitted),
      ]);
      if (mounted) {
        setState(() {
          _userName = results[0] as String;
          _jobCount = (results[1] as List).length;
          _pendingQuotes = (results[2] as List).length;
          _loading = false;
        });
      }
    } on Exception catch (e) {
      safePrint('Error loading dashboard: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        'Good morning, $_userName',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text("Here's your current workload", style: TextStyle(color: Colors.black54)),
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
                            count: '$_jobCount',
                            icon: Icons.work_outline,
                            color: const Color(0xFF1A56DB),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const JobListScreen()));
                              _loadDashboard();
                            },
                          ),
                          SummaryTile(
                            label: 'Quotes Pending',
                            count: '$_pendingQuotes',
                            icon: Icons.description_outlined,
                            color: Colors.orange,
                            onTap: () {},
                          ),
                          SummaryTile(
                            label: 'Variations Awaiting',
                            count: '–',
                            icon: Icons.edit_note,
                            color: Colors.purple,
                            onTap: () {},
                          ),
                          SummaryTile(
                            label: 'Claims Outstanding',
                            count: '–',
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
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteBuilderScreen()));
                            _loadDashboard();
                          },
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: const Center(
                          child: Text(
                            'No recent activity',
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
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
          if (i == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const JobListScreen())).then((_) => _loadDashboard());
          }
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: actions);
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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
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

