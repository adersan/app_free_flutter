import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/exercicio_model.dart';

class ExerciciosDashboardScreen extends StatefulWidget {
  final int usuarioId;

  const ExerciciosDashboardScreen({super.key, required this.usuarioId});

  @override
  State<ExerciciosDashboardScreen> createState() =>
      _ExerciciosDashboardScreenState();
}

class _ExerciciosDashboardScreenState extends State<ExerciciosDashboardScreen> {
  List<Exercicio> _exercicios = [];
  Map<String, int> _duracaoPorDia = {};
  int _totalHoje = 0;
  final int _metaDiaria = 30;
  int _passosEstimados = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarDados();
  }

  void _carregarDados() async {
    final lista = await DatabaseHelper().getExercicios(widget.usuarioId);
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Map<String, int> tempDuracoes = {};
    int totalHoje = 0;

    for (var e in lista) {
      tempDuracoes[e.data] = (tempDuracoes[e.data] ?? 0) + e.duracao;
      if (e.data == hoje) totalHoje += e.duracao;
    }

    setState(() {
      _exercicios = lista;
      _duracaoPorDia = tempDuracoes;
      _totalHoje = totalHoje;
      _passosEstimados = totalHoje * 100;
    });
  }

  List<BarChartGroupData> _gerarBarras() {
    final dias = List.generate(7, (i) {
      final dia = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('yyyy-MM-dd').format(dia);
    });

    return dias.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final duracao = _duracaoPorDia[data] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: duracao.toDouble(),
            width: 16,
            color: const Color(0xFF6C4F9E),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desempenho de Exercícios'),
        backgroundColor: const Color(0xFFE0CFFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo de hoje:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildResumoCard('Minutos hoje', '$_totalHoje min'),
                _buildResumoCard(
                  'Meta diária',
                  '$_metaDiaria min',
                  atingida: _totalHoje >= _metaDiaria,
                ),
                _buildResumoCard('Passos', '$_passosEstimados'),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Gráfico dos últimos 7 dias:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final diasSemana = [
                            'S',
                            'T',
                            'Q',
                            'Q',
                            'S',
                            'S',
                            'D',
                          ];
                          final index = value.toInt();
                          if (index >= 0 && index < diasSemana.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(diasSemana[index]),
                            );
                          } else {
                            return const Text('');
                          }
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: _gerarBarras(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCard(String titulo, String valor, {bool atingida = true}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: atingida ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
