import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesNotificacaoScreen extends StatefulWidget {
  const ConfiguracoesNotificacaoScreen({super.key});

  @override
  State<ConfiguracoesNotificacaoScreen> createState() =>
      _ConfiguracoesNotificacaoScreenState();
}

class _ConfiguracoesNotificacaoScreenState
    extends State<ConfiguracoesNotificacaoScreen> {
  int _tempoSelecionado = 5;
  final List<int> _opcoesTempo = [0, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
  }

  Future<void> _carregarConfiguracao() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tempoSelecionado = prefs.getInt('tempoNotificacao') ?? 5;
    });
  }

  Future<void> _salvarConfiguracao(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tempoNotificacao', valor);
    setState(() {
      _tempoSelecionado = valor;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuração salva!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Notificação'),
        backgroundColor: const Color(0xFFE0CFFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quanto tempo antes deseja ser notificado?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._opcoesTempo.map(
              (tempo) => RadioListTile(
                title: Text(
                  tempo == 0 ? 'Na hora exata' : '$tempo minutos antes',
                ),
                value: tempo,
                groupValue: _tempoSelecionado,
                onChanged: (value) {
                  _salvarConfiguracao(value as int);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
