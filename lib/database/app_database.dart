import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';
import '../models/journal_entry.dart';
import '../models/project.dart';
import '../models/party.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      p.join(databasePath, 'contractor_journal.db'),
      version: 2,
      onUpgrade: _onUpgrade,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        project_id INTEGER NOT NULL,
        debit_acc INTEGER NOT NULL,
        credit_acc INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL,
        party_id INTEGER,
        FOREIGN KEY(project_id) REFERENCES projects(id),
        FOREIGN KEY(debit_acc) REFERENCES accounts(id),
        FOREIGN KEY(credit_acc) REFERENCES accounts(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE parties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');


    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    for (final name in ['A Project', 'B Work', 'General']) {
      await db.insert('projects', {'name': name});
    }

    final accounts = <Map<String, String>>[
      {'name': 'Cash', 'type': 'asset'},
      {'name': 'Bank', 'type': 'asset'},
      {'name': 'Direct Labor', 'type': 'expense'},
      {'name': 'Subcontractor', 'type': 'expense'},
      {'name': 'Equipment Rental', 'type': 'expense'},
      {'name': 'Materials', 'type': 'expense'},
      {'name': 'Transport', 'type': 'expense'},
      {'name': 'Fuel', 'type': 'expense'},
      {'name': 'Office', 'type': 'expense'},
      {'name': 'Insurance', 'type': 'expense'},
      {'name': 'Donation', 'type': 'expense'},
      {'name': 'Software', 'type': 'expense'},
      {'name': 'Vehicle', 'type': 'expense'},
      {'name': 'Sales', 'type': 'revenue'},
    ];
    for (final account in accounts) {
      await db.insert('accounts', account);
    }
    final parties = <Map<String, String>>[
      {'name': 'রহিম সাহেব', 'type': 'customer'},
      {'name': 'করিম ট্রেডার্স', 'type': 'supplier'},
    ];
    for (final party in parties) {
      await db.insert('parties', party);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parties(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE entries ADD COLUMN party_id INTEGER');
    }
  }



  Future<List<Party>> getParties() async {
    final db = await database;
    final rows = await db.query('parties', orderBy: 'name');
    return rows.map(Party.fromMap).toList();
  }

  Future<int> insertParty(String name, String type) async {
    final db = await database;
    return db.insert('parties', {'name': name, 'type': type});
  }

  Future<int> deleteParty(int id) async {
    final db = await database;
    return db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final rows = await db.query('accounts', orderBy: 'id');
    return rows.map(Account.fromMap).toList();
  }

  Future<List<Project>> getProjects() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'id');
    return rows.map(Project.fromMap).toList();
  }

  Future<int> insertEntry(Map<String, Object?> entry) async {
    final db = await database;
    return db.insert('entries', entry);
  }

  Future<int> updateEntry(int id, Map<String, Object?> entry) async {
    final db = await database;
    return db.update('entries', entry, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JournalEntry>> getRecentEntries({int limit = 20}) async {
    final db = await database;
    final rows = await db.query('entries', orderBy: 'id DESC', limit: limit);
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<List<JournalEntry>> getEntries() async {
    final db = await database;
    final rows = await db.query('entries', orderBy: 'date DESC, id DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<List<JournalEntry>> getEntriesByAccount(int accountId) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'debit_acc = ? OR credit_acc = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<List<JournalEntry>> getEntriesByProject(int projectId) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }
}
