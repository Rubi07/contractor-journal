import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';
import '../models/account.dart';
import '../models/project.dart';
import '../models/party.dart';
import '../parser/parser.dart';

class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key, required this.draft, this.entryId});

  final DraftEntry draft;
  final int? entryId;

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Project> _projects = [];
  List<Party> _parties = [];
  int? _partyId;
  List<Account> _accounts = [];
  int? _projectId;
  int? _debitAccountId;
  int? _creditAccountId;
  late String _date;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _date = widget.draft.date;
    _amountController.text = widget.draft.amount == 0
        ? ''
        : widget.draft.amount.toStringAsFixed(
            widget.draft.amount == widget.draft.amount.roundToDouble() ? 0 : 2,
          );
    _noteController.text = widget.draft.note;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final projects = await AppDatabase.instance.getProjects();
    final accounts = await AppDatabase.instance.getAccounts();
    final parties = await AppDatabase.instance.getParties();
    final project = projects.where((item) => item.name == widget.draft.project).firstOrNull;
    final debit = accounts.where((item) => item.name == widget.draft.debitAcc).firstOrNull;
    final credit = accounts.where((item) => item.name == widget.draft.creditAcc).firstOrNull;

    if (!mounted) return;
    setState(() {
      _parties = parties;
      _partyId = widget.draft.partyId;
      _projects = projects;
      _accounts = accounts;
      _projectId = project?.id ?? projects.firstOrNull?.id;
      _debitAccountId = debit?.id ?? accounts.firstOrNull?.id;
      _creditAccountId = credit?.id ?? accounts.firstOrNull?.id;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      _date = '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক টাকা পরিমাণ দিন')),
      );
      return;
    }
    if (_projectId == null || _debitAccountId == null || _creditAccountId == null) return;

    final values = <String, Object?>{
      'date': _date,
      'party_id': _partyId,
      'project_id': _projectId,
      'debit_acc': _debitAccountId,
      'credit_acc': _creditAccountId,
      'amount': amount,
      'note': _noteController.text.trim(),
    };
    if (widget.entryId == null) {
      values['created_at'] = DateTime.now().toIso8601String();
      await AppDatabase.instance.insertEntry(values);
    } else {
      await AppDatabase.instance.updateEntry(widget.entryId!, values);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('খসড়া যাচাই করুন')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('তারিখ'),
                  subtitle: Text(_date),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'টাকা',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _partyId,
                  decoration: const InputDecoration(
                    labelText: 'পক্ষ (কাস্টমার/সাপ্লায়ার)',
                    border: OutlineInputBorder(),
                  ),
                  items: _parties.map((party) {
                    return DropdownMenuItem(
                      value: party.id,
                      child: Text('${party.name} (${party.type == 'customer' ? 'কাস্টমার' : 'সাপ্লায়ার'})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _partyId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _projectId,
                  decoration: const InputDecoration(
                    labelText: 'প্রকল্প',
                    border: OutlineInputBorder(),
                  ),
                  items: _projects.map((project) {
                    return DropdownMenuItem(value: project.id, child: Text(project.name));
                  }).toList(),
                  onChanged: (value) => setState(() => _projectId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _debitAccountId,
                  decoration: const InputDecoration(
                    labelText: 'ডেবিট হিসাব',
                    border: OutlineInputBorder(),
                  ),
                  items: _accounts.map((account) {
                    return DropdownMenuItem(value: account.id, child: Text(account.name));
                  }).toList(),
                  onChanged: (value) => setState(() => _debitAccountId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _creditAccountId,
                  decoration: const InputDecoration(
                    labelText: 'ক্রেডিট হিসাব',
                    border: OutlineInputBorder(),
                  ),
                  items: _accounts.map((account) {
                    return DropdownMenuItem(value: account.id, child: Text(account.name));
                  }).toList(),
                  onChanged: (value) => setState(() => _creditAccountId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'বিবরণ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('❌ বাতিল'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _confirm,
                        child: const Text('✅ কনফার্ম'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
