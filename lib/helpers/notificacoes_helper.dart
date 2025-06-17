import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacoesHelper {
  static final FlutterLocalNotificationsPlugin _notificacoesPlugin =
      FlutterLocalNotificationsPlugin();

  /// 🔥 Inicializa notificações
  static Future<void> inicializar() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings inicializacaoAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings configuracoes = InitializationSettings(
      android: inicializacaoAndroid,
    );

    await _notificacoesPlugin.initialize(configuracoes);
  }

  /// 🔔 Agendar notificação com opção de tempo antes (minutosAntes)
  static Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataHora,
    int minutosAntes = 0, // 🔥 Novo parâmetro para antecedência
  }) async {
    final dataNotificacao = dataHora.subtract(Duration(minutes: minutosAntes));

    await _notificacoesPlugin.zonedSchedule(
      id,
      titulo,
      corpo,
      tz.TZDateTime.from(dataNotificacao, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_atividades',
          'Atividades',
          channelDescription: 'Notificações de atividades do app',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// ❌ Cancelar uma notificação específica
  static Future<void> cancelarNotificacao(int id) async {
    await _notificacoesPlugin.cancel(id);
  }

  /// ❌ Cancelar todas as notificações
  static Future<void> cancelarTodas() async {
    await _notificacoesPlugin.cancelAll();
  }
}
