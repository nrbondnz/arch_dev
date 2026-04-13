import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/domain_helpers.dart';
import '../../widgets/status_badge.dart';
import 'job_detail_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  JobStatus? _filter;

  List<Job> get _filtered => _filter == null
      ? MockData.jobs
      : MockData.jobs.where((j) => j.status == _filter).toList();

  String _nextAction(Job job) => switch (job.status) {
        JobStatus.enquiry => 'Build quote',
        JobStatus.quoted => 'Awaiting client response',
        JobStatus.contracted => 'Set up work packages',
        JobStatus.mobilised => 'Complete mobilisation',
        JobStatus.inProgress => 'Active — logging daily progress',
        JobStatus.variationPending => 'Variation task outstanding',
        JobStatus.completed => 'Final account pending',
        JobStatus.closed => 'Closed',
      };

  @override
  Widget build(BuildContext context) {
    final filters = [null, JobStatus.enquiry, JobStatus.quoted, JobStatus.inProgress, JobStatus.completed];

    return Scaffold(
      appBar: AppBar(title: const Text('All Jobs')),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: filters.map((f) {
                final label = f == null ? 'All' : jobStatusLabel(f);
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: const Color(0xFF1A56DB).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF1A56DB),
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF1A56DB) : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('No jobs',
                        style: TextStyle(color: Colors.grey[400])))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _JobListTile(
                      job: _filtered[i],
                      nextAction: _nextAction(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Job — backend integration coming in Phase 2')),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _JobListTile extends StatelessWidget {
  final Job job;
  final String nextAction;

  const _JobListTile({required this.job, required this.nextAction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.siteAddress,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(job.clientName,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                StatusBadge.domainJob(job.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (job.totalContractValue > 0) ...[
                  Icon(Icons.attach_money,
                      size: 14, color: Colors.grey[500]),
                  Text(
                    formatNzd(job.totalContractValue),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.arrow_forward_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    nextAction,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
