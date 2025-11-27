import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session_model.dart';

class DatabaseHelper {
  // Singleton Pattern (Biar cuma ada 1 satpam di aplikasi)
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Cek: Kalau database belum ada, bikin baru. Kalau ada, pakai yang lama.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rehab_history.db');
    return _database!;
  }

  // Buka koneksi ke file database di HP
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Bikin Tabel (Mirip bikin Sheet di Excel)
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kg REAL,
        date TEXT,
        duration TEXT,
        status TEXT
      )
    ''');
  }

  // --- FUNGSI CRUD (Create, Read, Update, Delete) ---

  // 1. SIMPAN DATA BARU (Create)
  Future<int> create(SessionModel session) async {
    final db = await instance.database;
    return await db.insert('sessions', session.toMap());
  }

  // 2. BACA SEMUA DATA (Read)
  Future<List<SessionModel>> readAllSessions() async {
    final db = await instance.database;
    // Ambil semua data, urutkan dari yang terbaru (DESC)
    final result = await db.query('sessions', orderBy: 'date DESC');
    return result.map((json) => SessionModel.fromMap(json)).toList();
  }

  // 3. HAPUS SEMUA DATA (Opsional, buat bersih-bersih)
  Future<void> deleteAll() async {
    final db = await instance.database;
    await db.delete('sessions');
  }
}