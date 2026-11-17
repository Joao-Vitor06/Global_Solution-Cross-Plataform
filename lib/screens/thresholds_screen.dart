import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../core/utils/validators.dart';
import '../models/indicator.dart';
import '../models/thresholds.dart';
import '../providers/settings_provider.dart';

/// Formulário de configuração dos limiares de alerta.
class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<IndicatorType, TextEditingController> _controllers;
  late final TextEditingController _trendController;

  static const _ranges = <IndicatorType, (double, double)>{
    IndicatorType.water: (5, 90),
    IndicatorType.energy: (100, 1000),
    IndicatorType.climate: (20, 50),
    IndicatorType.air: (5, 150),
    IndicatorType.waste: (10, 200),
  };

  @override
  void initState() {
    super.initState();
    final current = context.read<SettingsProvider>().thresholds;
    _controllers = {
      for (final t in IndicatorType.values)
        t: TextEditingController(text: formatNumber(current.of(t))),
    };
    _trendController = TextEditingController(text: formatNumber(current.trendPct));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _trendController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final thresholds = Thresholds(
      values: {
        for (final t in IndicatorType.values) t: Validators.parseNumber(_controllers[t]!.text)!,
      },
      trendPct: Validators.parseNumber(_trendController.text)!,
    );
    await settings.saveThresholds(thresholds);
    messenger.showSnackBar(const SnackBar(content: Text('Limiares salvos. Alertas recalculados.')));
    navigator.pop();
  }

  void _restoreDefaults() {
    final defaults = Thresholds.defaults();
    setState(() {
      for (final t in IndicatorType.values) {
        _controllers[t]!.text = formatNumber(defaults.of(t));
      }
      _trendController.text = formatNumber(defaults.trendPct);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limiares de alerta')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Defina a partir de qual valor cada indicador gera alertas. Os alertas são recalculados na hora.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final t in IndicatorType.values) ...[
              TextFormField(
                controller: _controllers[t],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${t.title} (${t.unit})',
                  helperText: t.thresholdHint,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(t.icon),
                ),
                validator: (v) => Validators.number(v, min: _ranges[t]!.$1, max: _ranges[t]!.$2),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _trendController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Alta semanal para alerta de tendência (%)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
              ),
              validator: (v) => Validators.number(v, min: 1, max: 100),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar limiares'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _restoreDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Restaurar padrões'),
            ),
          ],
        ),
      ),
    );
  }
}
