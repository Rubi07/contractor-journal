import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/party.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  List<Party> _parties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final parties = await AppDatabase.instance.getParties();
    if (!mounted) return;
    setState(() {
      _parties = parties;
      _loading = false;
    });
  }

  Future<void> _addParty() async {
    final nameController = TextEditingController();
    String type = 'customer';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('নতুন পক্ষ যোগ করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'নাম',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'ধরন',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('কাস্টমার')),
                  DropdownMenuItem(value: 'supplier', child: Text('সাপ্লায়ার')),
                ],
                onChanged: (v) => setDialogState(() => type = v ?? 'customer'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('যোগ করুন'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await AppDatabase.instance.insertParty(nameController.text.trim(), type);
      _load();
    }
    nameController.dispose();
  }

  Future<void> _deleteParty(Party party) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মুছবেন?'),
        content: Text('${party.name} কে মুছে ফেলবেন?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('হ্যাঁ, মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppDatabase.instance.deleteParty(party.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: _parties.isEmpty
          ? const Center(
              child: Text(
                'এখনো কোনো পক্ষ যোগ করা হয়নি।\nনিচের + বাটনে চাপ দিন।',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _parties.length,
              itemBuilder: (context, index) {
                final party = _parties[index];
                return ListTile(
                  leading: Icon(
                    party.type == 'customer'
                        ? Icons.person_outline
                        : Icons.business_outlined,
                  ),
                  title: Text(party.name),
                  subtitle: Text(
                    party.type == 'customer' ? 'কাস্টমার' : 'সাপ্লায়ার',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteParty(party),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addParty,
        tooltip: 'নতুন পক্ষ',
        child: const Icon(Icons.add),
      ),
    );
  }
}
