import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;

  void _fazerLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      final user = await DatabaseHelper().getUser(
        _emailController.text.trim(),
        _senhaController.text.trim(),
      );

      setState(() {
        _carregando = false;
      });

      if (user != null) {
        // 🔥 Gera as atividades do dia após login
        await DatabaseHelper().gerarAtividadesDoDia(user.id!);

        if (!mounted) return; // ✅ Protege o uso do context após await

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => DashboardScreen(
                  nomeUsuario: user.nome,
                  usuarioId: user.id!,
                ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail ou senha inválidos')),
        );
      }
    }
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        obscureText: isPassword && !_senhaVisivel,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaVisivel = !_senhaVisivel;
                      });
                    },
                  )
                  : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo obrigatório';
          if (label == 'Email' && !value.contains('@')) return 'Email inválido';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFFE0CFFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput(
                'Email',
                _emailController,
                tipo: TextInputType.emailAddress,
              ),
              _buildInput('Senha', _senhaController, isPassword: true),
              const SizedBox(height: 20),
              _carregando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C4F9E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _fazerLogin,
                    child: const Text('Entrar', style: TextStyle(fontSize: 16)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
