import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../models/mock_data.dart';
import '../../utils/domain_helpers.dart';

class ContractSetupScreen extends StatefulWidget {
  final Job job;
  const ContractSetupScreen({super.key, required this.job});

  @override
  State<ContractSetupScreen> createState() => _ContractSetupScreenState();
}

class _ContractSetupScreenState extends State<ContractSetupScreen> {
  // Editable copies of mock stages for demo
  late List<_StageRow> _stages;

  final Map<String, bool> _mobilisation = {
    'RAMS approved': true,
    'Insurance certificates on file': true,
    'Materials ordered / delivery scheduled': false,
    'Scaffolding & site access confirmed': false,
    'Site induction completed': true,
  };

  @override
  void initState() {
    super.initState();
    final existing = MockData.stages[widget.job.id] ?? [];
    _stages = existing
        .map((s) => _StageRow(
              description: s.description,
              value: s.scheduledValue.toStringAsFixed(0),
              triggerType: s.triggerType,
              triggerValue: s.triggerValue,
              retention: (s.retentionRate * 100).toStringAsFixed(0),
            ))
        .toList();
    if (_stages.isEmpty) {
      _stages.add(_StageRow());
    }
  }

  double get _stageTotal => _stages.fold(0, (sum, s) {
        return sum + (double.tryParse(s.value) ?? 0);
      });

  @override
  Widget build(BuildContext context) {
    final contractValue = widget.job.totalContractValue;
    final diff = _stageTotal - contractValue;
    final balanced = diff.abs() < 0.01;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Setup'),
        actions: [
          TextButton(
            onPressed: balanced ? _save : null,
            child: Text('Save',
                style: TextStyle(
                    color: balanced ? const Color(0xFF1A56DB) : Colors.grey)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contract summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.business_center_outlined,
                      color: Color(0xFF1A56DB), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.job.siteAddress,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(widget.job.clientName,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  if (contractValue > 0)
                    Text(formatNzd(contractValue),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contract type & terms
            _SectionLabel('Contract Terms'),
            _FieldRow('Contract Type', widget.job.contractType),
            _FieldRow('Payment Terms', widget.job.paymentTerms),
            const SizedBox(height: 24),

            // Stages
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Payment Stages'),
                TextButton.icon(
                  onPressed: () => setState(() => _stages.add(_StageRow())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Stage', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1A56DB)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._stages.asMap().entries.map((e) =>
                _StageEditor(
                  index: e.key,
                  row: e.value,
                  onRemove: _stages.length > 1
                      ? () => setState(() => _stages.removeAt(e.key))
                      : null,
                  onChange: () => setState(() {}),
                )),

            // Total vs contract value
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: balanced
                    ? const Color(0xFF0E9F6E).withValues(alpha: 0.08)
                    : const Color(0xFFE3A008).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: balanced
                        ? const Color(0xFF0E9F6E).withValues(alpha: 0.3)
                        : const Color(0xFFE3A008).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                      balanced
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      color: balanced
                          ? const Color(0xFF0E9F6E)
                          : const Color(0xFFE3A008),
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      balanced
                          ? 'Stage total matches contract value: ${formatNzd(_stageTotal)}'
                          : 'Stage total ${formatNzdShort(_stageTotal)} — differs by \$${diff.abs().toStringAsFixed(2)} from contract value ${formatNzdShort(contractValue)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: balanced
                              ? const Color(0xFF0E9F6E)
                              : const Color(0xFFE3A008)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Mobilisation checklist
            _SectionLabel('Mobilisation Checklist'),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15))),
              child: Column(
                children: _mobilisation.entries.map((e) {
                  return CheckboxListTile(
                    title: Text(e.key, style: const TextStyle(fontSize: 13)),
                    value: e.value,
                    onChanged: (v) =>
                        setState(() => _mobilisation[e.key] = v ?? false),
                    activeColor: const Color(0xFF0E9F6E),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: balanced ? _save : null,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save Contract Setup'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Contract setup saved (demo — backend integration coming)')),
    );
    Navigator.pop(context);
  }
}

class _StageRow {
  String description;
  String value;
  StageTriggerType triggerType;
  String triggerValue;
  String retention;

  _StageRow({
    this.description = '',
    this.value = '',
    this.triggerType = StageTriggerType.milestone,
    this.triggerValue = '',
    this.retention = '10',
  });
}

class _StageEditor extends StatelessWidget {
  final int index;
  final _StageRow row;
  final VoidCallback? onRemove;
  final VoidCallback onChange;

  const _StageEditor({
    required this.index,
    required this.row,
    required this.onRemove,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB).withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A56DB))),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Stage',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            label: 'Description',
            initial: row.description,
            onChanged: (v) {
              row.description = v;
              onChange();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Value (NZD ex. GST)',
                  initial: row.value,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    row.value = v;
                    onChange();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  label: 'Retention %',
                  initial: row.retention,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    row.retention = v;
                    onChange();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TriggerPicker(row: row, onChange: onChange),
        ],
      ),
    );
  }
}

class _TriggerPicker extends StatefulWidget {
  final _StageRow row;
  final VoidCallback onChange;
  const _TriggerPicker({required this.row, required this.onChange});

  @override
  State<_TriggerPicker> createState() => _TriggerPickerState();
}

class _TriggerPickerState extends State<_TriggerPicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Trigger',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<StageTriggerType>(
          value: widget.row.triggerType,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: StageTriggerType.values.map((t) {
            final labels = {
              StageTriggerType.milestone: 'Milestone',
              StageTriggerType.date: 'Date',
              StageTriggerType.percentComplete: '% Complete',
              StageTriggerType.manual: 'Manual',
            };
            return DropdownMenuItem(value: t, child: Text(labels[t]!, style: const TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              widget.row.triggerType = v;
              widget.onChange();
              setState(() {});
            }
          },
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
        if (widget.row.triggerType != StageTriggerType.manual) ...[
          const SizedBox(height: 8),
          _Field(
            label: widget.row.triggerType == StageTriggerType.milestone
                ? 'Milestone name'
                : widget.row.triggerType == StageTriggerType.date
                    ? 'Date (e.g. 15 Jul 2026)'
                    : '% complete threshold',
            initial: widget.row.triggerValue,
            onChanged: (v) {
              widget.row.triggerValue = v;
              widget.onChange();
            },
          ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String initial;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    required this.initial,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initial,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  const _FieldRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.6)),
    );
  }
}
