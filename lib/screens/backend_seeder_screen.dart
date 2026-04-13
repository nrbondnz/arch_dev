import 'package:flutter/material.dart';
import '../services/backend_seeder.dart';

/// Developer screen for seeding the backend with canonical test data.
/// Accessible from the role select screen. Shows a live activity log as
/// each API call completes.
class BackendSeederScreen extends StatefulWidget {
  const BackendSeederScreen({super.key});

  @override
  State<BackendSeederScreen> createState() => _BackendSeederScreenState();
}

class _BackendSeederScreenState extends State<BackendSeederScreen> {
  final List<_LogEntry> _log = [];
  bool _running = false;
  bool _done = false;
  final _scrollCtrl = ScrollController();

  void _addLog(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() => _log.add(_LogEntry(message, isError: isError)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _done = false;
      _log.clear();
    });

    try {
      final seeder = BackendSeeder(onLog: (msg, {isError = false}) {
        _addLog(msg, isError: isError);
      });
      await seeder.seed();
      setState(() => _done = true);
    } on Exception catch (e) {
      _addLog('Fatal: $e', isError: true);
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Backend Data'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Data Seeder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                    'Creates J001 (InProgress + stages + WPs + variations + claim),\n'
                    'J002 (Quoted + quote with line items), J003 (Enquiry).\n'
                    'Requires an authenticated admin-manager session.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Run button
            FilledButton.icon(
              onPressed: _running ? null : _run,
              icon: _running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow),
              label: Text(_running
                  ? 'Seeding…'
                  : _done
                      ? 'Seed Again'
                      : 'Seed Test Data'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB)),
            ),
            const SizedBox(height: 12),

            // Activity log
            if (_log.isNotEmpty) ...[
              Row(children: [
                const Icon(Icons.terminal, size: 14, color: Colors.black45),
                const SizedBox(width: 6),
                Text('Activity log (${_log.length} events)',
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ]),
              const SizedBox(height: 6),
              Expanded(
                child: SelectionArea(
                  child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: _log.length,
                    itemBuilder: (context, i) {
                      final entry = _log[i];
                      if (entry.message.isEmpty) {
                        return const SizedBox(height: 6);
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          entry.message,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: entry.isError
                                ? const Color(0xFFFF6B6B)
                                : entry.message.startsWith('──')
                                    ? const Color(0xFF64DFDF)
                                    : entry.message.startsWith('All done')
                                        ? const Color(0xFF6BFF6B)
                                        : const Color(0xFFE0E0E0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Press "Seed Test Data" to begin.',
                      style: TextStyle(color: Colors.black38)),
                ),
              ),

            if (_done)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Done — back to role select'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogEntry {
  final String message;
  final bool isError;
  _LogEntry(this.message, {this.isError = false});
}
