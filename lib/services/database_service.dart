import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dreams.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dreams(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        content TEXT NOT NULL,
        image_url TEXT,
        ai_interpretation TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE dreams ADD COLUMN ai_interpretation TEXT');
    }
  }

  // 插入梦境记录
  Future<int> insertDream(DreamRecord dream) async {
    final db = await database;
    return await db.insert('dreams', {
      'title': dream.title,
      'time': dream.time,
      'content': dream.content,
      'image_url': dream.imageUrl,
      'ai_interpretation': dream.aiInterpretation,
    });
  }

  // 获取所有梦境记录
  Future<List<DreamRecord>> getAllDreams() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dreams', orderBy: 'time DESC');
    return List.generate(maps.length, (i) {
      return DreamRecord(
        id: maps[i]['id'],
        title: maps[i]['title'],
        time: maps[i]['time'],
        content: maps[i]['content'],
        imageUrl: maps[i]['image_url'],
        aiInterpretation: maps[i]['ai_interpretation'],
      );
    });
  }

  // 获取单个梦境记录
  Future<DreamRecord?> getDream(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dreams',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return DreamRecord(
        id: maps[0]['id'],
        title: maps[0]['title'],
        time: maps[0]['time'],
        content: maps[0]['content'],
        imageUrl: maps[0]['image_url'],
        aiInterpretation: maps[0]['ai_interpretation'],
      );
    }
    return null;
  }

  // 更新梦境记录
  Future<int> updateDream(DreamRecord dream) async {
    final db = await database;
    return await db.update(
      'dreams',
      {
        'title': dream.title,
        'time': dream.time,
        'content': dream.content,
        'image_url': dream.imageUrl,
        'ai_interpretation': dream.aiInterpretation,
      },
      where: 'id = ?',
      whereArgs: [dream.id],
    );
  }

  // 删除梦境记录
  Future<int> deleteDream(int id) async {
    final db = await database;
    return await db.delete(
      'dreams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// 梦境记录数据模型
class DreamRecord {
  final int? id;
  final String title;
  final String time;
  final String content;
  final String? imageUrl;
  final String? aiInterpretation;

  DreamRecord({
    this.id,
    required this.title,
    required this.time,
    required this.content,
    this.imageUrl,
    this.aiInterpretation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'content': content,
      'image_url': imageUrl,
      'ai_interpretation': aiInterpretation,
    };
  }

  factory DreamRecord.fromMap(Map<String, dynamic> map) {
    return DreamRecord(
      id: map['id'],
      title: map['title'],
      time: map['time'],
      content: map['content'],
      imageUrl: map['image_url'],
      aiInterpretation: map['ai_interpretation'],
    );
  }
}