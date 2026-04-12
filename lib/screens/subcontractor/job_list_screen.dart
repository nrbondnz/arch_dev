import 'package:flutter/material.dart';

import '../../widgets/status_badge.dart';
import 'job_detail_screen.dart';

/// Placeholder model — replace with Amplify DataStore / API model
class JobSummary {
  final String id;
  final String name;
  final String client;
  final String location;
  final JobStatus status;
  final String contractValue;
  final String progressPct;

  const JobSummary({
    required this.id,
    required this.name,
    required this.client,
    required this.location,
    required this.status,
    required this.contractValue,
    required this.progressPct,
  });
}

final _sampleJobs = [
  const JobSummary(
    id: 'J001',
    name: 'Parnell Residential – Stage 1',
    client: 'BuildPro NZ Ltd',
    location: 'Parnell, Auckland',
    status: JobStatus.accepted,
    contractValue: '\$148,000',
    progressPct: '62%',
  ),
  const JobSummary(
    id: 'J002',
    name: 'Wynyard Quarter Commercial',
    client: 'Apex Constructions NZ',
    location: 'Wynyard Quarter, Auckland',
    status: JobStatus.accepted,
    contractValue: '\$320,000',
    progressPct: '35%',
  ),
  const JobSummary(
    id: 'J003',
    name: 'East Tāmaki Warehouse',
    client: 'Urban Developments NZ',
    location: 'East Tāmaki, Auckland',
    status: JobStatus.pending,
    contractValue: 'TBC',
    progressPct: '0%',
  ),
  const JobSummary(
    id: 'J004',
    name: 'Newmarket Mixed Use',
    client: 'Premium Build NZ',
    location: 'Newmarket, Auckland',
    status: JobStatus.submitted,
    contractValue: '\$210,000',
    progressPct: '0%',
  ),
];

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _sampleJobs
        : _sampleJobs.where((j) => j.status.name.toLowerCase() == _filter.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs')),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Accepted', 'Submitted', 'Pending'].map((label) {
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) => _JobCard(job: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobSummary job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(job: job))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusBadge(job.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(job.client, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              Text(job.location, style: const TextStyle(color: Colors.black38, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(icon: Icons.attach_money, label: job.contractValue),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.pie_chart_outline, label: 'Progress ${job.progressPct}'),
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
