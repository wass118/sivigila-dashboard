import 'dart:convert';
import 'dart:typed_data';

import '../../core/errors/humanizer_failure.dart';

/// Formatos de importación previstos.
enum ImportFormat { txt, docx, pdf, image }

class ImportedDocument {
  const ImportedDocument({required this.text, required this.sourceName,
      required this.format});
  final String text;
  final String sourceName;
  final ImportFormat format;
}

/// Punto de extensión para cargar archivos (v1.1: TXT/DOCX/PDF; v2.0: OCR).
abstract interface class DocumentImportService {
  bool supports(ImportFormat format);
  Future<ImportedDocument> import(Uint8List bytes,
      {required String fileName, required ImportFormat format});
}

/// Implementación actual: solo texto plano UTF-8. DOCX, PDF e imágenes
/// devuelven [UnsupportedFeatureFailure] de forma explícita.
class BasicDocumentImportService implements DocumentImportService {
  const BasicDocumentImportService();

  @override
  bool supports(ImportFormat format) => format == ImportFormat.txt;

  @override
  Future<ImportedDocument> import(Uint8List bytes,
      {required String fileName, required ImportFormat format}) async {
    if (format != ImportFormat.txt) {
      throw UnsupportedFeatureFailure(
          'La importación de ${format.name.toUpperCase()} es una '
          'funcionalidad futura. Por ahora pegue el texto en el editor.');
    }
    final text = utf8.decode(bytes, allowMalformed: true)
        .replaceAll('\r\n', '\n')
        .replaceAll('﻿', '');
    return ImportedDocument(text: text, sourceName: fileName, format: format);
  }
}
