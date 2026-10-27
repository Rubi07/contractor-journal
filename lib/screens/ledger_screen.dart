import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../models/project.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Account> _accounts = [];
  List<Project> _projects = [];
  String? _selection;
  List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final accounts = await AppDatabase.instance.getAccounts();
    final projects = await AppDatabase.instance.getProjects();
    final selection = 'account:${accounts.first.id}';
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _projects = projects;
      _selection = selection;
    });
    await _loadEntries(selection);
  }

  Future<void> _loadEntries(String selection) async {
    final parts = selection.split(':');
    final id = int.parse(parts[1]);
    final entries = parts[0] == 'account'
        ? await AppDatabase.instance.getEntriesByAccount(id)
        : await AppDatabase.instance.getEntriesByProject(id);
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  String _accountName(int id) => _accounts.firstWhere((item) => item.id == id).name;
  String _projectName(int id) => _projects.firstWhere((item) => item.id == id).name;

  @override
  Widget build(BuildContext context) {
    final accountSelection = _selection?.startsWith('account:') ?? false;
    double running = 0;
    return Scaffold(
      appBar: AppBar(title: const Text('খতিয়ান')),
      body: _selection == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: _selection,
                  decoration: const InputDecoration(
                    labelText: 'হিসাব বা প্রকল্প',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final account in _accounts)
                      DropdownMenuItem(
                        value: 'account:${account.id}',
                        child: Text('হিসাব: ${account.name}'),
                      ),
                    for (final project in _projects)
                      DropdownMenuItem(
                        value: 'project:${project.id}',
                        child: Text('প্রকল্প: ${project.name}'),
                      ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _selection = value);
                    await _loadEntries(value);
                  },
                ),
              ),
              Expanded(child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final id = int.parse(_selection!.split(':')[1]);
                  final affectsDebit = accountSelection && entry.debitAccountId == id;
                  final affectsCredit = accountSelection && entry.creditAccountId == id;
                  if (accountSelection) {
                    if (affectsDebit && affectsCredit) {
                      running += 0;
                    } else if (affectsDebit) {
                      running += entry.amount;
                    } else if (affectsCredit) {
                      running -= entry.amount;
                    }
                  } else {
                    running += entry.amount;
                  }
                  return ListTile(
                    title: Text(entry.note.isEmpty ? 'বিবরণ নেই' : entry.note),
                    subtitle: Text('${entry.date} · ${_projectName(entry.projectId)} · ${_accountName(entry.debitAccountId)} / ${_accountName(entry.creditAccountId)}'),
                    trailing: Text(accountSelection
                        ? '${affectsDebit ? '+' : affectsCredit ? '-' : ''}${entry.amount.toStringAsFixed(2)}'
                        : entry.amount.toStringAsFixed(2)),
                  );
                },
              )),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text('চলতি ব্যালেন্স: ${running.toStringAsFixed(2)}', textAlign: TextAlign.right),
              ),
            ]),
    );
  }
}
