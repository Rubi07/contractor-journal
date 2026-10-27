import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Account> _accounts = [];
  List<JournalEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await AppDatabase.instance.getAccounts();
    final entries = await AppDatabase.instance.getEntries();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _entries = entries;
      _loading = false;
    });
  }

  Map<int, double> _balances() {
    final balances = <int, double>{};
    for (final account in _accounts) {
      balances[account.id] = 0;
    }
    for (final entry in _entries) {
      balances[entry.debitAccountId] = balances[entry.debitAccountId]! + entry.amount;
      balances[entry.creditAccountId] = balances[entry.creditAccountId]! - entry.amount;
    }
    return balances;
  }

  Future<void> _exportCsv() async {
    final projects = await AppDatabase.instance.getProjects();
    final accounts = await AppDatabase.instance.getAccounts();
    final entries = await AppDatabase.instance.getEntries();
    String name(List<_NamedItem> items, int id) => items.firstWhere((item) => item.id == id).name;
    final projectsNamed = projects.map((item) => _NamedItem(item.id, item.name)).toList();
    final accountsNamed = accounts.map((item) => _NamedItem(item.id, item.name)).toList();
    final rows = <List<Object?>>[
      ['date', 'project', 'debit_account', 'credit_account', 'amount', 'note', 'created_at'],
      for (final entry in entries)
        [
          entry.date,
          name(projectsNamed, entry.projectId),
          name(accountsNamed, entry.debitAccountId),
          name(accountsNamed, entry.creditAccountId),
          entry.amount,
          entry.note,
          entry.createdAt,
        ],
    ];
    final file = File('${Directory.systemTemp.path}/contractor_journal.csv');
    await file.writeAsString(const ListToCsvConverter().convert(rows));
    await SharePlus.instance.share(ShareParams(
      text: 'কন্ট্রাক্টর জার্নাল CSV',
      files: [XFile(file.path)],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balances();
    final expenses = _accounts.where((account) => account.type == 'expense').fold<double>(
      0,
      (sum, account) => sum + (balances[account.id] ?? 0),
    );
    final income = _accounts.where((account) => account.type == 'revenue').fold<double>(
      0,
      (sum, account) => sum - (balances[account.id] ?? 0),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                FilledButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.share),
                  label: const Text('CSV রপ্তানি করুন'),
                ),
                const SizedBox(height: 24),
                const Text('ট্রায়াল ব্যালেন্স', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final account in _accounts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(account.name),
                    trailing: Text((balances[account.id] ?? 0).toStringAsFixed(2)),
                  ),
                const Divider(),
                const Text('আয় ও ব্যয়', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ListTile(title: const Text('মোট আয়'), trailing: Text(income.toStringAsFixed(2))),
                ListTile(title: const Text('মোট ব্যয়'), trailing: Text(expenses.toStringAsFixed(2))),
                ListTile(title: const Text('নিট ফলাফল'), trailing: Text((income - expenses).toStringAsFixed(2))),
              ]),
            ),
    );
  }
}

class _NamedItem {
  const _NamedItem(this.id, this.name);

  final int id;
  final String name;
}
