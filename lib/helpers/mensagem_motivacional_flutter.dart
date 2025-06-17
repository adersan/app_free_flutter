import 'dart:math';

String gerarMensagemMotivacional(int totalRealizado, int dias) {
  final int atividadesEsperadas = dias * 3;
  final double percentual =
      (atividadesEsperadas == 0)
          ? 0
          : (totalRealizado / atividadesEsperadas * 100);

  if (percentual >= 90) {
    return _mensagemFaixaAlta(percentual);
  } else if (percentual >= 70) {
    return _mensagemFaixaMediaAlta(percentual);
  } else if (percentual >= 50) {
    return _mensagemFaixaMediaBaixa(percentual);
  } else {
    return _mensagemFaixaBaixa(percentual);
  }
}

String _mensagemFaixaAlta(double p) {
  final mensagens = [
    "🎯 Incrível! Você cumpriu ${p.toStringAsFixed(1)}% da sua rotina. Continue nesse ritmo!",
    "🔥 Excelente! ${p.toStringAsFixed(1)}% realizado. Você é inspiração!",
    "🏆 Parabéns! ${p.toStringAsFixed(1)}% das suas atividades concluídas. Mantenha-se assim!",
    "🌟 Desempenho extraordinário! ${p.toStringAsFixed(1)}% concluído. Você é incrível!",
  ];
  return _aleatoria(mensagens);
}

String _mensagemFaixaMediaAlta(double p) {
  final mensagens = [
    "🚀 Muito bem! ${p.toStringAsFixed(1)}% de adesão. Você está no caminho certo!",
    "💪 Ótimo trabalho! ${p.toStringAsFixed(1)}%. Com um pouco mais de esforço, chega nos 100%!",
    "✨ Você está quase lá! ${p.toStringAsFixed(1)}% cumprido. Continue com disciplina.",
    "🌈 Excelente progresso! ${p.toStringAsFixed(1)}% das atividades feitas. Foco e garra!",
  ];
  return _aleatoria(mensagens);
}

String _mensagemFaixaMediaBaixa(double p) {
  final mensagens = [
    "⚠️ Você está no caminho, ${p.toStringAsFixed(1)}%! Vamos tentar melhorar nos próximos dias!",
    "🌱 Progresso acontecendo! ${p.toStringAsFixed(1)}%. Que tal reforçar um pouco mais amanhã?",
    "🏃‍♂️ Está andando, mas dá pra acelerar! ${p.toStringAsFixed(1)}%. Vamos lá!",
    "👊 Você consegue! ${p.toStringAsFixed(1)}% concluído. Bora focar um pouco mais!",
  ];
  return _aleatoria(mensagens);
}

String _mensagemFaixaBaixa(double p) {
  final mensagens = [
    "💡 Vamos focar! Apenas ${p.toStringAsFixed(1)}% cumprido. Recomece com energia!",
    "🚧 Pouco progresso (${p.toStringAsFixed(1)}%). Não desanime, cada passo conta!",
    "🔄 O começo pode ser difícil. ${p.toStringAsFixed(1)}% realizado. Que tal recomeçar hoje mesmo?",
    "💪 Força! ${p.toStringAsFixed(1)}% não é o fim. Um novo começo começa agora!",
  ];
  return _aleatoria(mensagens);
}

String _aleatoria(List<String> lista) {
  final random = Random();
  return lista[random.nextInt(lista.length)];
}
