import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

Future<Uint8List> gerarRelatorioPDF({
  required String nomeUsuario,
  required String periodo,
  required int totalMed,
  required int totalExe,
  required int totalNut,
  required String mensagemMotivacional,
  required Map<String, Map<String, int>> dadosPorDia,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Relatório de Desempenho',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Usuário: $nomeUsuario', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Período: $periodo', style: pw.TextStyle(fontSize: 12)),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Resumo Geral',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Bullet(text: 'Medicamentos: $totalMed'),
            pw.Bullet(text: 'Exercícios: $totalExe'),
            pw.Bullet(text: 'Refeições: $totalNut'),
            pw.SizedBox(height: 12),
            pw.Text(
              'Mensagem Motivacional',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(mensagemMotivacional),
            pw.SizedBox(height: 16),
            pw.Text(
              'Atividades por Dia',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Data', 'Medic.', 'Exerc.', 'Nutri.'],
              data:
                  dadosPorDia.entries.map((e) {
                    final data = e.key;
                    final v = e.value;
                    return [
                      data,
                      (v['med'] ?? 0).toString(),
                      (v['exe'] ?? 0).toString(),
                      (v['nut'] ?? 0).toString(),
                    ];
                  }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.deepPurple),
              cellAlignment: pw.Alignment.center,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                'Relatório gerado automaticamente pelo aplicativo',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
