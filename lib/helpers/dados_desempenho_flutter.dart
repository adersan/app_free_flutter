import 'package:intl/intl.dart';
import '../database/database_helper.dart';

Future<Map<String, Map<String, int>>> carregarDadosDesempenho(
  int usuarioId,
  int dias,
) async {
  final db = await DatabaseHelper().database;
  final hoje = DateTime.now();
  final inicio = hoje.subtract(Duration(days: dias - 1));

  // Formato das datas
  final dataHoje = DateFormat('yyyy-MM-dd').format(hoje);
  final dataInicio = DateFormat('yyyy-MM-dd').format(inicio);

  // Buscar atividades executadas no período
  final atividades = await db.query(
    'atividades_geradas',
    where: 'usuarioId = ? AND data BETWEEN ? AND ? AND executado = 1',
    whereArgs: [usuarioId, dataInicio, dataHoje],
  );

  // Mapa resultado
  Map<String, Map<String, int>> mapa = {};

  for (var a in atividades) {
    final data = a['data'] as String;
    final tipo = a['tipo'] as String;

    mapa.putIfAbsent(data, () => {'med': 0, 'exe': 0, 'nut': 0});

    if (tipo == 'medicamento') {
      mapa[data]!['med'] = (mapa[data]!['med'] ?? 0) + 1;
    } else if (tipo == 'exercicio') {
      mapa[data]!['exe'] = (mapa[data]!['exe'] ?? 0) + 1;
    } else if (tipo == 'nutricao') {
      mapa[data]!['nut'] = (mapa[data]!['nut'] ?? 0) + 1;
    }
  }

  return mapa;
}
