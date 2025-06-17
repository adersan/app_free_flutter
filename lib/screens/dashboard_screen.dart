import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'medicamentos_screen.dart';
import 'exercicios_screen.dart';
import 'nutricao_screen.dart';
import 'desempenho_relatorio_screen.dart';
import 'configuracoes_notificacao_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String nomeUsuario;
  final int usuarioId;

  const DashboardScreen({
    super.key,
    required this.nomeUsuario,
    required this.usuarioId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _atividades = [];

  @override
  void initState() {
    super.initState();
    _carregarAtividades();
  }

  Future<void> _carregarAtividades() async {
    final atividades = await DatabaseHelper().getTodasAtividades(
      widget.usuarioId,
    );

    final pendentes = atividades.where((a) => a['executado'] == 0).toList();

    pendentes.sort((a, b) {
      final dataA = DateFormat('yyyy-MM-dd').parse(a['data']);
      final dataB = DateFormat('yyyy-MM-dd').parse(b['data']);

      final partesA = (a['horario'] as String).split(':');
      final partesB = (b['horario'] as String).split(':');

      final horaA = TimeOfDay(
        hour: int.tryParse(partesA[0]) ?? 0,
        minute: int.tryParse(partesA[1]) ?? 0,
      );
      final horaB = TimeOfDay(
        hour: int.tryParse(partesB[0]) ?? 0,
        minute: int.tryParse(partesB[1]) ?? 0,
      );

      if (dataA.compareTo(dataB) != 0) {
        return dataA.compareTo(dataB);
      }
      return horaA.hour != horaB.hour
          ? horaA.hour.compareTo(horaB.hour)
          : horaA.minute.compareTo(horaB.minute);
    });

    setState(() {
      _atividades = pendentes;
    });
  }

  Color _getStatusColor(String data, String horario) {
    final agora = DateTime.now();

    final dataAtividade = DateFormat('yyyy-MM-dd').parse(data);
    final partes = horario.split(':');
    final hora = int.tryParse(partes[0]) ?? 0;
    final minuto = int.tryParse(partes[1]) ?? 0;

    final dataHorario = DateTime(
      dataAtividade.year,
      dataAtividade.month,
      dataAtividade.day,
      hora,
      minuto,
    );

    if (agora.isAfter(dataHorario)) {
      return Colors.red;
    }
    return const Color(0xFF6C4F9E);
  }

  Widget _buildBotaoCheck({
    required Color cor,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(Icons.check_circle, color: cor, size: 26),
      onPressed: onPressed,
    );
  }

  Future<void> _excluirAtividade(Map<String, dynamic> atividade) async {
    await DatabaseHelper().excluirAtividadesPorItem(
      idItem: atividade['id_item'],
      tipo: atividade['tipo'],
      usuarioId: widget.usuarioId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atividade excluída com sucesso!')),
    );

    _carregarAtividades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        backgroundColor: const Color(0xFFE0CFFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConfiguracoesNotificacaoScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${widget.nomeUsuario}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A468E),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Resumo das suas atividades:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildCard(context, 'Medicamentos', Icons.medication, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              MedicamentosScreen(usuarioId: widget.usuarioId),
                    ),
                  );
                  _carregarAtividades();
                }),
                _buildCard(
                  context,
                  'Exercícios',
                  Icons.fitness_center,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                ExerciciosScreen(usuarioId: widget.usuarioId),
                      ),
                    );
                    _carregarAtividades();
                  },
                ),
                _buildCard(
                  context,
                  'Desempenho/Relatório',
                  Icons.show_chart,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DesempenhoRelatorioScreen(
                              usuarioId: widget.usuarioId,
                            ),
                      ),
                    );
                    _carregarAtividades();
                  },
                ),
                _buildCard(
                  context,
                  'Nutrição',
                  Icons.restaurant_menu,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => NutricaoScreen(usuarioId: widget.usuarioId),
                      ),
                    );
                    _carregarAtividades();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Próximas atividades:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _atividades.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhuma atividade para hoje. 🎉',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _atividades.length,
                        itemBuilder: (context, index) {
                          final a = _atividades[index];

                          final data = a['data'] as String;
                          final horario = a['horario'] as String;
                          final nome = a['nome'];
                          final id = a['id'];

                          final cor = _getStatusColor(data, horario);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(nome),
                              subtitle: Text(
                                '$horario - ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(data))}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildBotaoCheck(
                                    cor: cor,
                                    onPressed: () async {
                                      await DatabaseHelper()
                                          .toggleAtividadeExecutado(id);
                                      _carregarAtividades();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _excluirAtividade(a),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 72) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFF6C4F9E)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5A468E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
