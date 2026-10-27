import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../database/app_database.dart';
import '../models/journal_entry.dart';
import '../parser/parser.dart';
import 'draft_screen.dart';
import 'ledger_screen.dart';
import 'parties_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speech = SpeechToText();
  List<JournalEntry> _entries = [];
  bool _listening = false;
  int _navigationIndex = 0;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await AppDatabase.instance.getRecentEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _refreshVersion++;
    });
  }

  Future<void> _openDraft(DraftEntry draft, {int? entryId}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DraftScreen(draft: draft, entryId: entryId)),
    );
    if (saved == true) await _loadEntries();
  }

  Future<void> _editEntry(JournalEntry entry) async {
    final projects = await AppDatabase.instance.getProjects();
    final accounts = await AppDatabase.instance.getAccounts();
    if (!mounted) return;
    await _openDraft(
      DraftEntry(
        date: entry.date,
        project: projects.firstWhere((item) => item.id == entry.projectId).name,
        debitAcc: accounts.firstWhere((item) => item.id == entry.debitAccountId).name,
        creditAcc: accounts.firstWhere((item) => item.id == entry.creditAccountId).name,
        amount: entry.amount,
        note: entry.note,
      ),
      entryId: entry.id,
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('হিসাব মুছবেন?'),
        content: const Text('এই হিসাবটি স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteEntry(entry.id);
    await _loadEntries();
  }

  Future<void> _startVoiceEntry() async {
    final available = await _speech.initialize();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('মাইক্রোফোন পাওয়া যায়নি')),
      );
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: 'bn_IN'),
      onResult: (result) async {
        if (!result.finalResult || result.recognizedWords.trim().isEmpty) return;
        await _speech.stop();
        if (!mounted) return;
        setState(() => _listening = false);
        await _openDraft(BengaliJournalParser.parse(result.recognizedWords));
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _addManually() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    _openDraft(DraftEntry(
      date: date,
      project: 'General',
      debitAcc: 'Direct Labor',
      creditAcc: 'Cash',
      amount: 0,
      note: '',
    ));
  }

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: FilledButton.icon(
              onPressed: _listening ? _stopListening : _startVoiceEntry,
              icon: Icon(_listening ? Icons.stop : Icons.mic, size: 48),
              label: Text(
                _listening ? 'থামুন' : '🎤 বলুন',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('সাম্প্রতিক হিসাব', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('এখনও কোনো হিসাব নেই')),
            ),
          for (final entry in _entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.note.isEmpty ? 'হিসাবের বিবরণ নেই' : entry.note),
              subtitle: Text('${entry.date} · টাকা ${entry.amount.toStringAsFixed(2)}'),
              leading: const Icon(Icons.receipt_long),
              trailing: PopupMenuButton<String>(
                tooltip: 'বিকল্প',
                onSelected: (value) {
                  if (value == 'edit') {
                    _editEntry(entry);
                  } else if (value == 'delete') {
                    _deleteEntry(entry);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('এডিট')),
                  PopupMenuItem(value: 'delete', child: Text('মুছুন')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      PartiesScreen(key: ValueKey('parties-$_refreshVersion')),
      LedgerScreen(key: ValueKey('ledger-$_refreshVersion')),
      ReportScreen(key: ValueKey('report-$_refreshVersion')),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('কন্ট্রাক্টর জার্নাল')),
      body: pages[_navigationIndex],
      floatingActionButton: _navigationIndex == 0
          ? FloatingActionButton(
              onPressed: _addManually,
              tooltip: 'নিজে লিখুন',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navigationIndex,
        onDestinationSelected: (index) => setState(() => _navigationIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'হোম'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'পক্ষ'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'খতিয়ান'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'রিপোর্ট'),
        ],
      ),
    );
  }
}
