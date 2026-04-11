import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VariationFormScreen extends StatefulWidget {
  const VariationFormScreen({super.key});

  @override
  State<VariationFormScreen> createState() => _VariationFormScreenState();
}

class _VariationFormScreenState extends State<VariationFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _impactController = TextEditingController();

  String _selectedReason = 'Design change';
  final List<String> _attachments = [];

  final _reasons = [
    'Design change',
    'Site instruction',
    'Unforeseen conditions',
    'RFI response',
    'Client request',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raise Variation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Variations require approval before they are added to your contract value.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Job
            const _Label('Job'),
            DropdownButtonFormField<String>(
              value: 'J001 – Fitzroy Residential',
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'J001 – Fitzroy Residential', child: Text('J001 – Fitzroy Residential')),
                DropdownMenuItem(value: 'J002 – North Melbourne Commercial', child: Text('J002 – North Melbourne Commercial')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),

            // Title
            const _Label('Variation Title'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Additional brickwork – window revision',
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            const _Label('Reason for Variation'),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedReason = v ?? _selectedReason),
            ),
            const SizedBox(height: 16),

            // Description
            const _Label('Detailed Description'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe what additional work is required and why...',
              ),
            ),
            const SizedBox(height: 16),

            // Price
            const _Label('Variation Price (ex. GST)'),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 4),
            if (_priceController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'inc. GST: \$${((double.tryParse(_priceController.text) ?? 0) * 1.1).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            // Programme impact
            const _Label('Programme Impact'),
            TextFormField(
              controller: _impactController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. 2 additional days required',
                suffixText: 'days',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Supporting evidence
            Row(
              children: [
                const _Label('Supporting Evidence'),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: const Text('Attach'),
                  onPressed: () => setState(() => _attachments.add('Site_Instruction_${_attachments.length + 1}.pdf')),
                ),
              ],
            ),
            if (_attachments.isEmpty)
              const Text('No attachments (photos, site instructions)', style: TextStyle(color: Colors.black38, fontSize: 13)),
            ..._attachments.map((f) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(f, style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => _attachments.remove(f)),
              ),
            )),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Submit Variation Request', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Variation?'),
        content: const Text('This will send the variation request to the main contractor for approval. You will be notified once a decision is made.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Variation submitted – status: Pending Approval')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
