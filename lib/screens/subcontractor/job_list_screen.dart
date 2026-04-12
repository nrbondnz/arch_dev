import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/ModelProvider.dart';
import '../../services/job_service.dart';
import '../../utils/status_helpers.dart';
import '../../widgets/status_badge.dart';
import 'job_detail_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  String _filter = 'All';
  List<Job> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      final jobs = await JobService.listJobs();
      if (mounted) setState(() { _jobs = jobs; _loading = false; });
    } on Exception catch (e) {
      safePrint('Error loading jobs: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Job> get _filtered {
    if (_filter == 'All') return _jobs;
    return _jobs.where((j) => j.status.name == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Job',
            onPressed: () => _showCreateJobDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Enquiry', 'Quoted', 'Contracted'].map((label) {
                final selected = _filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = label),
                  ),
                );
              }).toList(),
            ),
          ),

          // Job list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No jobs found', style: TextStyle(color: Colors.black54)))
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _JobCard(
                            job: _filtered[i],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => JobDetailScreen(job: _filtered[i])),
                              );
                              _loadJobs(); // Refresh on return
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreateJobDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Job Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clientCtrl,
                decoration: const InputDecoration(labelText: 'Client', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || clientCtrl.text.isEmpty) return;
              Navigator.pop(context);
              try {
                await JobService.createJob(
                  jobName: nameCtrl.text,
                  client: clientCtrl.text,
                  location: locationCtrl.text.isEmpty ? null : locationCtrl.text,
                );
                _loadJobs();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job created')),
                  );
                }
              } on Exception catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final value = (job.contractValue ?? 0) > 0
        ? '\$${job.contractValue!.toStringAsFixed(0)}'
        : 'TBC';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.jobName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusBadge.job(job.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(job.client, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              if (job.location != null)
                Text(job.location!, style: const TextStyle(color: Colors.black38, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(icon: Icons.attach_money, label: value),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
