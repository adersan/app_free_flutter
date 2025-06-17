import 'package:flutter/material.dart';
import '../models/medicamento_model.dart';
import '../database/database_helper.dart';
import 'editar_medicamento_screen.dart';

class MedicamentosScreen extends StatefulWidget {
  final int usuarioId;
  const MedicamentosScreen({super.key, required this.usuarioId});

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final _nomeController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _unidadeSelecionada = 'mg';
  int _vezesPorDia = 1;
  TimeOfDay _horarioInicial = TimeOfDay.now();

  List<Medicamento> _medicamentos = [];

  @override
  void initState() {
    super.initState();
    _carregarMedicamentos();
  }

  void _carregarMedicamentos() async {
    final lista = await DatabaseHelper().getMedicamentos(widget.usuarioId);
    setState(() {
      _medicamentos = lista;
    });
  }

  void _selecionarHorarioInicial() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horarioInicial,
    );
    if (picked != null) {
      setState(() {
        _horarioInicial = picked;
      });
    }
  }

  List<String> _gerarHorarios(TimeOfDay base, int vezes) {
    List<String> horarios = [];
    int intervalo = (24 / vezes).round();
    for (int i = 0; i < vezes; i++) {
      final hora = (base.hour + (i * intervalo)) % 24;
      final minuto = base.minute;
      final time = TimeOfDay(hour: hora, minute: minuto);
      horarios.add(time.format(context));
    }
    return horarios;
  }

  void _salvarMedicamento() async {
    if (_formKey.currentState!.validate()) {
      final horariosGerados = _gerarHorarios(_horarioInicial, _vezesPorDia);

      final medicamento = Medicamento(
        nome: _nomeController.text,
        quantidade: double.parse(_quantidadeController.text),
        unidade: _unidadeSelecionada,
        vezesPorDia: _vezesPorDia,
        horarioInicial: _horarioInicial.format(context),
        horariosGerados: horariosGerados,
        observacoes:
            _observacoesController.text.isEmpty
                ? ''
                : _observacoesController.text,
        usuarioId: widget.usuarioId,
      );

      await DatabaseHelper().insertMedicamento(medicamento);

      // 🔥 Notificações em segundo plano
      DatabaseHelper().gerarAtividadesDoDia(widget.usuarioId);

      _resetarFormulario();
      _carregarMedicamentos();

      _scaffoldMessengerKey.currentState!.showSnackBar(
        const SnackBar(content: Text('Medicamento salvo com sucesso!')),
      );
    }
  }

  void _excluirMedicamento(Medicamento medicamento) async {
    await DatabaseHelper().deleteMedicamento(medicamento.id!);
    await DatabaseHelper().excluirAtividadesPorItem(
      idItem: medicamento.id!,
      tipo: 'medicamento',
      usuarioId: widget.usuarioId,
    );

    DatabaseHelper().gerarAtividadesDoDia(widget.usuarioId);

    _scaffoldMessengerKey.currentState!.showSnackBar(
      const SnackBar(content: Text('Medicamento excluído com sucesso!')),
    );

    _carregarMedicamentos();
  }

  void _resetarFormulario() {
    _formKey.currentState?.reset();
    _nomeController.clear();
    _quantidadeController.clear();
    _observacoesController.clear();
    _vezesPorDia = 1;
    _unidadeSelecionada = 'mg';
    _horarioInicial = TimeOfDay.now();
    setState(() {});
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    TextInputType tipo = TextInputType.text,
    bool obrigatorio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator:
            obrigatorio
                ? (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horarioLabel = _horarioInicial.format(context);

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medicamentos'),
          backgroundColor: const Color(0xFFE0CFFF),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInput('Nome', _nomeController),
                    _buildInput(
                      'Quantidade',
                      _quantidadeController,
                      tipo: TextInputType.number,
                    ),
                    Row(
                      children: [
                        const Text('Unidade:'),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _unidadeSelecionada,
                          items:
                              ['mg', 'ml', 'un']
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => _unidadeSelecionada = value!),
                        ),
                        const Spacer(),
                        const Text('Vezes/dia:'),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: _vezesPorDia,
                          items:
                              List.generate(6, (i) => i + 1)
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text('$v'),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _vezesPorDia = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Horário inicial: $horarioLabel'),
                    ),
                    TextButton.icon(
                      onPressed: _selecionarHorarioInicial,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Selecionar horário'),
                    ),
                    _buildInput(
                      'Observações (opcional)',
                      _observacoesController,
                      obrigatorio: false,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C4F9E),
                      ),
                      onPressed: _salvarMedicamento,
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _medicamentos.isEmpty
                        ? const Center(
                          child: Text('Nenhum medicamento cadastrado.'),
                        )
                        : ListView.builder(
                          itemCount: _medicamentos.length,
                          itemBuilder: (context, index) {
                            final m = _medicamentos[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(
                                  '${m.nome} - ${m.quantidade}${m.unidade}',
                                ),
                                subtitle: Text(
                                  'Horários: ${m.horariosGerados.join(', ')}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () async {
                                        final atualizado = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => EditarMedicamentoScreen(
                                                  medicamento: m,
                                                ),
                                          ),
                                        );
                                        if (atualizado == true) {
                                          DatabaseHelper().gerarAtividadesDoDia(
                                            widget.usuarioId,
                                          );
                                          _carregarMedicamentos();

                                          _scaffoldMessengerKey.currentState!
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Medicamento atualizado com sucesso!',
                                                  ),
                                                ),
                                              );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _excluirMedicamento(m),
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
      ),
    );
  }
}
