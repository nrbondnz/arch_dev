import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../widgets/status_badge.dart';

class WorkPackageScreen extends StatelessWidget {
  final Job job;
  const WorkPackageScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final packages = MockData.workPackages[job.id] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Work Packages')),
      body: packages.isEmpty
          ? _EmptyPackages(job: job)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Job header
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFF1A56DB), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(job.siteAddress,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      StatusBadge.domainJob(job.status),
                    ],
                  ),
                ),

                ...packages.map((p) => _PackageCard(pkg: p)),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPackageSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Work Package'),
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddPackageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddPackageSheet(job: job),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final WorkPackage pkg;
  const _PackageCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                child: Text(pkg.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              StatusBadge.workPackage(pkg.status),
            ],
          ),
          const SizedBox(height: 10),

          // Site manager row
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text('Site Manager: ',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(pkg.siteManagerName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => _reassign(context),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1A56DB),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Reassign', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dates
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 15, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                '${_fmtDate(pkg.plannedStart)} → ${_fmtDate(pkg.plannedEnd)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Resources
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 15, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(pkg.resources,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),

          if (pkg.status == WorkPackageStatus.variationPending) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFE3A008).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFE3A008).withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: Color(0xFFE3A008), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Site manager has a pending work plan update task',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFE3A008)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _reassign(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reassign Work Package'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Tom Chen', 'Alex Rivera', 'Sam Park'].map((name) {
            return ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1A56DB),
                  child: Icon(Icons.person, color: Colors.white, size: 18)),
              title: Text(name),
              trailing: name == pkg.siteManagerName
                  ? const Icon(Icons.check, color: Color(0xFF0E9F6E))
                  : null,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reassigned to $name (demo)')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1]} ${d.year}';
}

class _EmptyPackages extends StatelessWidget {
  final Job job;
  const _EmptyPackages({required this.job});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No work packages yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Create a work package to assign a site manager',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}

class _AddPackageSheet extends StatefulWidget {
  final Job job;
  const _AddPackageSheet({required this.job});

  @override
  State<_AddPackageSheet> createState() => _AddPackageSheetState();
}

class _AddPackageSheetState extends State<_AddPackageSheet> {
  final _descCtrl = TextEditingController();
  final _resCtrl = TextEditingController();
  String _selectedSM = 'Tom Chen';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Work Package',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSM,
            decoration: const InputDecoration(
                labelText: 'Assign Site Manager',
                border: OutlineInputBorder()),
            items: ['Tom Chen', 'Alex Rivera', 'Sam Park']
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => _selectedSM = v ?? _selectedSM),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resCtrl,
            decoration: const InputDecoration(
                labelText: 'Resources (crew, equipment)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Work package created (demo — backend integration coming)')),
                );
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Create Work Package'),
            ),
          ),
        ],
      ),
    );
  }
}
