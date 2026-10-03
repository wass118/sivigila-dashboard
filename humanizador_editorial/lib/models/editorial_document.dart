import 'editorial_request.dart';

/// Documento procesado guardado en el historial local.
class EditorialDocument {
  const EditorialDocument({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.domainId,
    required this.goalId,
    required this.intensityName,
    required this.originalText,
    this.generatedText,
    this.auditStatus,
    this.isDemo = false,
  });

  final String id;
  final DateTime createdAt;
  final String title;
  final String domainId;
  final String goalId;
  final String intensityName;
  final String originalText;
  final String? generatedText;
  final String? auditStatus;
  final bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'domainId': domainId,
        'goalId': goalId,
        'intensity': intensityName,
        'originalText': originalText,
        'generatedText': generatedText,
        'auditStatus': auditStatus,
        'demo': isDemo,
      };

  factory EditorialDocument.fromJson(Map<String, dynamic> json) =>
      EditorialDocument(
        id: json['id'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        title: json['title'] as String? ?? 'Sin título',
        domainId: json['domainId'] as String? ?? 'general',
        goalId: json['goalId'] as String? ?? '',
        intensityName: json['intensity'] as String? ?? '',
        originalText: json['originalText'] as String? ?? '',
        generatedText: json['generatedText'] as String?,
        auditStatus: json['auditStatus'] as String?,
        isDemo: json['demo'] as bool? ?? false,
      );

  /// Opciones aproximadas para reabrir el documento en el editor.
  EditorialOptions toOptions() =>
      EditorialOptions.fromJson({'domainId': domainId, 'goalId': goalId,
          'intensity': intensityName});
}
