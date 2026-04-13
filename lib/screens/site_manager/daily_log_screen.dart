import 'package:flutter/material.dart';

import '../../models/domain.dart';

class DailyLogScreen extends StatefulWidget {
  final WorkPackage workPackage;

  const DailyLogScreen({super.key, required this.workPackage});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  late DateTime _date;
  final _notesCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();
  final List<_LabourEntry> _labour = [_LabourEntry()];

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _materialsCtrl.dispose();
    super.dispose();
  }

  double get _totalHours =>
      _labour.fold(0, (sum, e) => sum + (double.tryParse(e.hoursCtrl.text) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Daily Log"),
        actions: [
          TextButton(
            onPressed: _notesCtrl.text.isNotEmpty ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                  color: _notesCtrl.text.isNotEmpty
                      ? const Color(0xFF1A56DB)
                      : Colors.grey),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline notice
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      size: 14, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Logs save locally first — synced when connected.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),

            // Date
            _SectionLabel('Date'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF1A56DB)),
                    const SizedBox(width: 10),
                    Text(_fmtDate(_date),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('Tap to change',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Work package info
            _SectionLabel('Work Package'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.15)),
              ),
              child: Text(
                widget.workPackage.description,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),

            // Labour entries
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Labour'),
                TextButton.icon(
                  onPressed: () => setState(() => _labour.add(_LabourEntry())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Person', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1A56DB)),
                ),
              ],
            ),
            ..._labour.asMap().entries.map(
                  (e) => _LabourRow(
                    entry: e.value,
                    index: e.key,
                    canRemove: _labour.length > 1,
                    onRemove: () => setState(() => _labour.removeAt(e.key)),
                    onChange: () => setState(() {}),
                  ),
                ),
            if (_totalHours > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total labour hours',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text('${_totalHours.toStringAsFixed(1)}h',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),

            // Progress notes
            _SectionLabel('Progress Notes'),
            TextField(
              controller: _notesCtrl,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'What was done today? Any issues, delays, or observations?',
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Materials used
            _SectionLabel('Materials Used (optional)'),
            TextField(
              controller: _materialsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. 800 bricks, 12 bags mortar, wall ties',
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Photos placeholder
            _SectionLabel('Photos (optional)'),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Camera / gallery — backend integration coming')),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Add Site Photos', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A56DB),
                side: const BorderSide(color: Color(0xFF1A56DB)),
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _notesCtrl.text.isNotEmpty ? _save : null,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save Daily Log'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '* Saved locally until sync is available',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Log for ${_fmtDate(_date)} saved (${_totalHours.toStringAsFixed(1)}h)'),
        backgroundColor: const Color(0xFF0E9F6E),
      ),
    );
    Navigator.pop(context);
  }

  String _fmtDate(DateTime d) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _LabourEntry {
  final nameCtrl = TextEditingController();
  final hoursCtrl = TextEditingController();
}

class _LabourRow extends StatelessWidget {
  final _LabourEntry entry;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChange;

  const _LabourRow({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Person name
          Expanded(
            flex: 3,
            child: TextField(
              controller: entry.nameCtrl,
              onChanged: (_) => onChange(),
              decoration: InputDecoration(
                labelText: 'Person ${index + 1}',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          // Hours
          SizedBox(
            width: 70,
            child: TextField(
              controller: entry.hoursCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => onChange(),
              decoration: const InputDecoration(
                labelText: 'Hours',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.6)),
    );
  }
}
