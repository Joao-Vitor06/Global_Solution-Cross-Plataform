import 'package:flutter/material.dart';

enum OccurrenceCategory { water, energy, weather, air, waste, other }

extension OccurrenceCategoryX on OccurrenceCategory {
  String get label => switch (this) {
        OccurrenceCategory.water => 'Água (vazamento, falta d\'água)',
        OccurrenceCategory.energy => 'Energia (queda, oscilação)',
        OccurrenceCategory.weather => 'Clima (calor, alagamento)',
        OccurrenceCategory.air => 'Ar (fumaça, queimada, poeira)',
        OccurrenceCategory.waste => 'Resíduos (lixo acumulado)',
        OccurrenceCategory.other => 'Outro serviço público',
      };

  IconData get icon => switch (this) {
        OccurrenceCategory.water => Icons.water_drop_outlined,
        OccurrenceCategory.energy => Icons.bolt_outlined,
        OccurrenceCategory.weather => Icons.thunderstorm_outlined,
        OccurrenceCategory.air => Icons.air,
        OccurrenceCategory.waste => Icons.recycling_outlined,
        OccurrenceCategory.other => Icons.report_outlined,
      };
}

/// Ocorrência registrada por cidadão. Não guarda nome, contato nem localização exata:
/// apenas a zona (região ampla) escolhida em uma lista.
class Occurrence {
  const Occurrence({
    required this.id,
    required this.category,
    required this.description,
    required this.zoneId,
    required this.severity,
    required this.createdAt,
  });

  factory Occurrence.fromJson(Map<String, dynamic> json) => Occurrence(
        id: json['id'] as String,
        category: OccurrenceCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => OccurrenceCategory.other,
        ),
        description: json['description'] as String,
        zoneId: json['zoneId'] as String,
        severity: (json['severity'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final OccurrenceCategory category;
  final String description;
  final String zoneId;

  /// 1 = baixa, 2 = média, 3 = alta.
  final int severity;
  final DateTime createdAt;

  String get severityLabel => switch (severity) {
        3 => 'Alta',
        2 => 'Média',
        _ => 'Baixa',
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'description': description,
        'zoneId': zoneId,
        'severity': severity,
        'createdAt': createdAt.toIso8601String(),
      };
}
