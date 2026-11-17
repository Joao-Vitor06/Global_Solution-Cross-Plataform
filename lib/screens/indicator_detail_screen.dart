import 'package:flutter/material.dart';

import '../models/indicator.dart';
import '../widgets/indicator_dashboard.dart';

/// Detalhe de um indicador (rota nomeada com parâmetro [IndicatorType]).
class IndicatorDetailScreen extends StatelessWidget {
  const IndicatorDetailScreen({super.key, required this.type});

  final IndicatorType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type.label)),
      body: IndicatorDashboard(type: type),
    );
  }
}
