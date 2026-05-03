import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'certificate_device_save.dart';
import 'notification_service.dart';

class CertificateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _certificateKey(String language) =>
      'advanced_${language.toLowerCase()}';

  Future<bool> hasEarnedCertificate(String userId, String language) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection('users').doc(userId).get();
      final List<String> certificates = List<String>.from(
        doc.data()?['certificates'] as List<dynamic>? ?? <dynamic>[],
      );
      return certificates.contains(_certificateKey(language));
    } catch (e) {
      return false;
    }
  }

  Future<void> saveCertificateEarned(String userId, String language) async {
    try {
      await _db.collection('users').doc(userId).set(<String, dynamic>{
        'certificates':
            FieldValue.arrayUnion(<String>[_certificateKey(language)]),
        'badgesEarned': FieldValue.arrayUnion(<String>['Advanced Scholar']),
      }, SetOptions(merge: true));
      debugPrint('CERTIFICATE: Saved for $language (+ Advanced Scholar badge)');
    } catch (e) {
      debugPrint('CERTIFICATE ERROR: $e');
    }
  }

  Future<void> generateAndShareCertificate({
    required String userName,
    required String language,
    required int score,
    required DateTime dateEarned,
  }) async {
    try {
      final pw.Document pdf = pw.Document();

      final String dateStr = DateFormat('MMMM dd, yyyy').format(dateEarned);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFF5B6BE8),
                  width: 8,
                ),
                borderRadius: pw.BorderRadius.circular(16),
              ),
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: <pw.Widget>[
                  pw.Text(
                    'LINGUAFLOW',
                    style: pw.TextStyle(
                      fontSize: 14,
                      letterSpacing: 6,
                      color: PdfColor.fromInt(0xFF5B6BE8),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(
                    color: PdfColor.fromInt(0xFF5B6BE8),
                    thickness: 2,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Certificate of Achievement',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF2D2F45),
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'This certifies that',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColor.fromInt(0xFF9A9EB5),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    userName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF5B6BE8),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'has successfully completed the',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColor.fromInt(0xFF9A9EB5),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '$language Advanced Level',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF2D2F45),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'with a score of $score%',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColor.fromInt(0xFF27A06A),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(
                    color: PdfColor.fromInt(0xFFD1D3D8),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text(
                        'Date: $dateStr',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor.fromInt(0xFF9A9EB5),
                        ),
                      ),
                      pw.Text(
                        'LinguaFlow Language Learning',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor.fromInt(0xFF9A9EB5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final List<int> pdfBytes = await pdf.save();

      if (!kIsWeb) {
        try {
          final String? savedPath =
              await saveCertificatePdfToDevice(pdfBytes, language);
          if (savedPath != null) {
            debugPrint('CERTIFICATE: Saved to $savedPath');
            await NotificationService().showCertificatePdfSavedNotification(
              fileName: p.basename(savedPath),
            );
          }
        } catch (e) {
          debugPrint('CERTIFICATE save error: $e');
        }
      }

      await Printing.sharePdf(
        bytes: Uint8List.fromList(pdfBytes),
        filename: 'LinguaFlow_${language}_Certificate.pdf',
      );

      debugPrint('CERTIFICATE: PDF generated and shared.');
    } catch (e, st) {
      debugPrint('CERTIFICATE ERROR generating PDF: $e');
      debugPrint('CERTIFICATE STACK: $st');
    }
  }
}
