import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/song.dart';

class ExportService {
  static Future<void> shareSongText(Song song) async {
    final text = '''
${song.title}
${song.author} • ${song.category} ${song.year != null ? '• ${song.year}' : ''}

${song.lyrics}

---
Chorale Antsan'ny Fitia
Paroisse Saint François d'Assise
Tsararivotra Ambalavao
Via app Antsan'ny Fitia
''';
    await Share.share(text, subject: song.title);
  }

  static Future<Uint8List> generateSongPdf(Song song) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Chorale Antsan'ny Fitia",
              style: pw.TextStyle(fontSize: 10, color: PdfColors.green800, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "Paroisse Saint François d'Assise - Tsararivotra Ambalavao",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Antsan'ny Fitia - ${song.author}",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber}/${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Text(
            song.title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${song.category} • ${song.author}${song.year != null ? ' • ${song.year}' : ''}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            song.lyrics,
            style: const pw.TextStyle(fontSize: 13, lineSpacing: 4),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> shareSongPdf(Song song) async {
    final bytes = await generateSongPdf(song);
    await Printing.sharePdf(bytes: bytes, filename: '${_sanitize(song.title)}.pdf');
  }

  static Future<void> printSong(Song song) async {
    final bytes = await generateSongPdf(song);
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  static Future<File> saveSongPdf(Song song) async {
    final bytes = await generateSongPdf(song);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${_sanitize(song.title)}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> exportAllSongsPdf(List<Song> songs) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          List<pw.Widget> widgets = [];
          widgets.add(
            pw.Center(
              child: pw.Column(
                children: [
                  pw.SizedBox(height: 120),
                  pw.Text("Chorale Antsan'ny Fitia",
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  pw.SizedBox(height: 12),
                  pw.Text("Paroisse Saint François d'Assise",
                      style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  pw.Text("Tsararivotra Ambalavao",
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                  pw.SizedBox(height: 40),
                  pw.Text("Recueil de chants",
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text("${songs.length} chants",
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  pw.SizedBox(height: 40),
                  pw.Text("Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                ],
              ),
            ),
          );
          return widgets;
        },
      ),
    );

    // Table des matières
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Table des matières'),
          pw.SizedBox(height: 10),
          ...songs.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        child: pw.Text('${e.key + 1}. ${e.value.title}',
                            style: const pw.TextStyle(fontSize: 11))),
                    pw.Text(e.value.category,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              )),
        ],
      ),
    );

    // Chaque chant
    for (var song in songs) {
      pdf.addPage(
        pw.MultiPage(
          header: (c) => pw.Text(song.title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
          footer: (c) => pw.Text('Antsan\'ny Fitia - page ${c.pageNumber}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          build: (c) => [
            pw.Text('${song.category} • ${song.author}${song.year != null ? ' • ${song.year}' : ''}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 14),
            pw.Text(song.lyrics, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
          ],
        ),
      );
    }

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Antsan_ny_Fitia_Recueil.pdf');
  }

  static String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_')
        .replaceAll("'", '');
  }
}
