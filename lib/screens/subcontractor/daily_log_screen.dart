import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _logDate = DateTime.now();
  final _labourController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_MaterialEntry> _materials = [];
  final List<String> _photoLabels = []; // Placeholder — real impl uses S3 pre-signed URLs
  bool _delaysOccurred = false;
  final _delayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Progress Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            const _SectionLabel('Date'),
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(_formatDate(_logDate), style: const TextStyle(fontSize: 15)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.black45),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Job selection
            const _SectionLabel('Job'),
            DropdownButtonFormField<String>(
              value: 'J001 – Parnell Residential',
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'J001 – Parnell Residential', child: Text('J001 – Parnell Residential')),
                DropdownMenuItem(value: 'J002 – Wynyard Quarter Commercial', child: Text('J002 – Wynyard Quarter Commercial')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),

            // Labour
            const _SectionLabel('Labour Hours'),
            TextFormField(
              controller: _labourController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. 8',
                suffixText: 'hrs',
              ),
            ),
            const SizedBox(height: 16),

            // Progress notes
            const _SectionLabel('Work Completed Today'),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe what was completed on site today...',
              ),
            ),
            const SizedBox(height: 16),

            // Materials
            Row(
              children: [
                const _SectionLabel('Materials Used'),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  onPressed: () => setState(() => _materials.add(_MaterialEntry())),
                ),
              ],
            ),
            if (_materials.isEmpty)
              const Text('No materials recorded', style: TextStyle(color: Colors.black38, fontSize: 13)),
            ..._materials.asMap().entries.map((e) => _MaterialRow(
              entry: e.value,
              onDelete: () => setState(() => _materials.removeAt(e.key)),
              onChanged: () => setState(() {}),
            )),
            const SizedBox(height: 16),

            // Delays
            const _SectionLabel('Delays / Disruptions'),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delays occurred today', style: TextStyle(fontSize: 14)),
              value: _delaysOccurred,
              onChanged: (v) => setState(() => _delaysOccurred = v),
            ),
            if (_delaysOccurred) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _delayController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe cause and impact...',
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Photo uploads (placeholder)
            const _SectionLabel('Site Photos'),
            _PhotoUploadArea(
              photos: _photoLabels,
              onAdd: () => setState(() => _photoLabels.add('Photo ${_photoLabels.length + 1}')),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Daily Log', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';

  String _month(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _logDate = picked);
  }

  void _submit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily log saved – ProgressUpdated event published')),
    );
    Navigator.pop(context);
  }
}

class _MaterialEntry {
  String name = '';
  String quantity = '';
  String unit = 'm²';
}

class _MaterialRow extends StatelessWidget {
  final _MaterialEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _MaterialRow({required this.entry, required this.onDelete, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Material'),
              onChanged: (v) => entry.name = v,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextFormField(
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Qty'),
              keyboardType: TextInputType.number,
              onChanged: (v) => entry.quantity = v,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: DropdownButtonFormField<String>(
              value: entry.unit,
              isDense: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'm²', child: Text('m²')),
                DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                DropdownMenuItem(value: 'bags', child: Text('bags')),
                DropdownMenuItem(value: 'lm', child: Text('lm')),
              ],
              onChanged: (v) => entry.unit = v ?? 'm²',
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _PhotoUploadArea extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAdd;
  const _PhotoUploadArea({required this.photos, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.black38),
                  SizedBox(height: 4),
                  Text('Add Photo', style: TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),
          ),
          // Photo placeholders
          ...photos.map((label) => Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image, color: Colors.black38, size: 32),
                    Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38)),
                  ],
                ),
              )),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }
}
