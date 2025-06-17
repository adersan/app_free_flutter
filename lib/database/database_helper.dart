import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/medicamento_model.dart';
import '../models/exercicio_model.dart';
import '../models/nutricao_model.dart';
import '../helpers/notificacoes_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('saude_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = join(await getDatabasesPath(), filePath);
    return await openDatabase(path, version: 3, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        email TEXT UNIQUE,
        senha TEXT,
        idade INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        quantidade REAL,
        unidade TEXT,
        vezesPorDia INTEGER,
        horarioInicial TEXT,
        horariosGerados TEXT,
        observacoes TEXT,
        usuarioId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE exercicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        tipo TEXT,
        duracao INTEGER,
        data TEXT,
        horario TEXT,
        diasSemana TEXT,
        observacoes TEXT,
        usuarioId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE nutricao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT,
        descricao TEXT,
        horario TEXT,
        diasSemana TEXT,
        observacoes TEXT,
        usuarioId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE atividades_geradas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_item INTEGER,
        tipo TEXT,
        nome TEXT,
        data TEXT,
        horario TEXT,
        executado INTEGER DEFAULT 0,
        usuarioId INTEGER
      )
    ''');
  }

  // ===================== CRUD USUÁRIO =====================
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('usuarios', user.toMap());
  }

  Future<User?> getUser(String email, String senha) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [email, senha],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // ===================== CONFIGURAÇÃO DE NOTIFICAÇÃO =====================
  Future<int> obterTempoNotificacao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('tempoNotificacao') ?? 5;
  }

  // ===================== GERAR ATIVIDADES + NOTIFICAÇÕES =====================
  Future<void> gerarAtividadesDoDia(int usuarioId) async {
    final db = await database;
    final minutosAntesNotificacao = await obterTempoNotificacao();

    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hojeSemana = DateFormat('EEEE', 'pt_BR').format(DateTime.now());

    // 🔥 MEDICAMENTOS
    final medicamentos = await getMedicamentos(usuarioId);
    for (var m in medicamentos) {
      for (var h in m.horariosGerados) {
        final existe = await db.query(
          'atividades_geradas',
          where:
              'usuarioId = ? AND id_item = ? AND tipo = ? AND data = ? AND horario = ?',
          whereArgs: [usuarioId, m.id, 'medicamento', hoje, h],
        );
        if (existe.isEmpty) {
          await db.insert('atividades_geradas', {
            'id_item': m.id,
            'tipo': 'medicamento',
            'nome': 'Tomar ${m.nome}',
            'data': hoje,
            'horario': h,
            'executado': 0,
            'usuarioId': usuarioId,
          });

          final partes = h.split(':');
          final dataHora = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(partes[0]),
            int.parse(partes[1]),
          );

          final idNotificacao = gerarIdNotificacao(
            usuarioId: usuarioId,
            idItem: m.id!,
            data: hoje,
            horario: h,
          );

          await NotificacoesHelper.agendarNotificacao(
            id: idNotificacao,
            titulo: 'Hora de tomar medicamento',
            corpo: 'Tomar ${m.nome} agora.',
            dataHora: dataHora,
            minutosAntes: minutosAntesNotificacao,
          );
        }
      }
    }

    // 🔥 EXERCÍCIOS
    final exercicios = await getExercicios(usuarioId);
    for (var e in exercicios) {
      if (e.diasSemana.contains('Todos') || e.diasSemana.contains(hojeSemana)) {
        final existe = await db.query(
          'atividades_geradas',
          where:
              'usuarioId = ? AND id_item = ? AND tipo = ? AND data = ? AND horario = ?',
          whereArgs: [usuarioId, e.id, 'exercicio', hoje, e.horario],
        );
        if (existe.isEmpty) {
          await db.insert('atividades_geradas', {
            'id_item': e.id,
            'tipo': 'exercicio',
            'nome': e.nome,
            'data': hoje,
            'horario': e.horario,
            'executado': 0,
            'usuarioId': usuarioId,
          });

          final partes = e.horario.split(':');
          final dataHora = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(partes[0]),
            int.parse(partes[1]),
          );

          final idNotificacao = gerarIdNotificacao(
            usuarioId: usuarioId,
            idItem: e.id!,
            data: hoje,
            horario: e.horario,
          );

          await NotificacoesHelper.agendarNotificacao(
            id: idNotificacao,
            titulo: 'Hora do exercício!',
            corpo: '${e.nome} está programado para agora.',
            dataHora: dataHora,
            minutosAntes: minutosAntesNotificacao,
          );
        }
      }
    }

    // 🔥 NUTRIÇÃO
    final refeicoes = await getNutricao(usuarioId);
    for (var r in refeicoes) {
      if (r.diasSemana.contains('Todos') || r.diasSemana.contains(hojeSemana)) {
        final existe = await db.query(
          'atividades_geradas',
          where:
              'usuarioId = ? AND id_item = ? AND tipo = ? AND data = ? AND horario = ?',
          whereArgs: [usuarioId, r.id, 'nutricao', hoje, r.horario],
        );
        if (existe.isEmpty) {
          await db.insert('atividades_geradas', {
            'id_item': r.id,
            'tipo': 'nutricao',
            'nome': '${r.tipo}: ${r.descricao}',
            'data': hoje,
            'horario': r.horario,
            'executado': 0,
            'usuarioId': usuarioId,
          });

          final partes = r.horario.split(':');
          final dataHora = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(partes[0]),
            int.parse(partes[1]),
          );

          final idNotificacao = gerarIdNotificacao(
            usuarioId: usuarioId,
            idItem: r.id!,
            data: hoje,
            horario: r.horario,
          );

          await NotificacoesHelper.agendarNotificacao(
            id: idNotificacao,
            titulo: 'Hora da refeição!',
            corpo: '${r.tipo}: ${r.descricao} está programado agora.',
            dataHora: dataHora,
            minutosAntes: minutosAntesNotificacao,
          );
        }
      }
    }
  }

  // 🔢 Gerar ID ÚNICO da notificação
  int gerarIdNotificacao({
    required int usuarioId,
    required int idItem,
    required String data,
    required String horario,
  }) {
    final dataNum = data.replaceAll('-', '');
    final horarioNum = horario.replaceAll(':', '');
    final idString = '$usuarioId$idItem$dataNum$horarioNum';
    return idString.hashCode.abs();
  }

  // 🔥 EXCLUIR ATIVIDADES ASSOCIADAS
  Future<void> excluirAtividadesPorItem({
    required int idItem,
    required String tipo,
    required int usuarioId,
  }) async {
    final db = await database;
    await db.delete(
      'atividades_geradas',
      where: 'id_item = ? AND tipo = ? AND usuarioId = ?',
      whereArgs: [idItem, tipo, usuarioId],
    );
  }

  // ===================== CRUD MEDICAMENTOS =====================
  Future<int> insertMedicamento(Medicamento medicamento) async {
    final db = await database;
    return await db.insert('medicamentos', medicamento.toMap());
  }

  Future<List<Medicamento>> getMedicamentos(int usuarioId) async {
    final db = await database;
    final maps = await db.query(
      'medicamentos',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
    return List.generate(maps.length, (i) => Medicamento.fromMap(maps[i]));
  }

  Future<int> updateMedicamento(Medicamento medicamento) async {
    final db = await database;
    return await db.update(
      'medicamentos',
      medicamento.toMap(),
      where: 'id = ?',
      whereArgs: [medicamento.id],
    );
  }

  Future<int> deleteMedicamento(int id) async {
    final db = await database;
    return await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== CRUD EXERCÍCIOS =====================
  Future<int> insertExercicio(Exercicio exercicio) async {
    final db = await database;
    return await db.insert('exercicios', exercicio.toMap());
  }

  Future<List<Exercicio>> getExercicios(int usuarioId) async {
    final db = await database;
    final maps = await db.query(
      'exercicios',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
    return List.generate(maps.length, (i) => Exercicio.fromMap(maps[i]));
  }

  Future<int> updateExercicio(Exercicio exercicio) async {
    final db = await database;
    return await db.update(
      'exercicios',
      exercicio.toMap(),
      where: 'id = ?',
      whereArgs: [exercicio.id],
    );
  }

  Future<int> deleteExercicio(int id) async {
    final db = await database;
    return await db.delete('exercicios', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== CRUD NUTRIÇÃO =====================
  Future<int> insertNutricao(Nutricao nutricao) async {
    final db = await database;
    return await db.insert('nutricao', nutricao.toMap());
  }

  Future<List<Nutricao>> getNutricao(int usuarioId) async {
    final db = await database;
    final maps = await db.query(
      'nutricao',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
    return List.generate(maps.length, (i) => Nutricao.fromMap(maps[i]));
  }

  Future<int> updateNutricao(Nutricao nutricao) async {
    final db = await database;
    return await db.update(
      'nutricao',
      nutricao.toMap(),
      where: 'id = ?',
      whereArgs: [nutricao.id],
    );
  }

  Future<int> deleteNutricao(int id) async {
    final db = await database;
    return await db.delete('nutricao', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== ATIVIDADES =====================
  Future<List<Map<String, dynamic>>> getTodasAtividades(int usuarioId) async {
    final db = await database;
    return await db.query(
      'atividades_geradas',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<int> toggleAtividadeExecutado(int id) async {
    final db = await database;
    final result = await db.query(
      'atividades_geradas',
      columns: ['executado'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return 0;

    final atual = result.first['executado'] == 1 ? 0 : 1;

    return await db.update(
      'atividades_geradas',
      {'executado': atual},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAtividadesExecutadasPorPeriodo(
    int usuarioId,
    DateTime inicio,
    DateTime fim,
  ) async {
    final db = await database;
    final dataInicio = DateFormat('yyyy-MM-dd').format(inicio);
    final dataFim = DateFormat('yyyy-MM-dd').format(fim);

    return await db.query(
      'atividades_geradas',
      where: 'usuarioId = ? AND executado = 1 AND data BETWEEN ? AND ?',
      whereArgs: [usuarioId, dataInicio, dataFim],
    );
  }
}
