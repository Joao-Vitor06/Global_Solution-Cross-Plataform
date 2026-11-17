import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/validators.dart';
import '../models/occurrence.dart';
import '../models/zone.dart';
import '../providers/occurrences_provider.dart';

/// Formulário de registro de ocorrência anônima, com validação.
class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({super.key});

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  OccurrenceCategory? _category;
  Zone? _zone;
  int _severity = 2;
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<OccurrencesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await provider.add(
      category: _category!,
      description: _descriptionController.text,
      zoneId: _zone!.id,
      severity: _severity,
    );
    messenger.showSnackBar(const SnackBar(content: Text('Ocorrência registrada de forma anônima.')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Seu relato é anônimo. Não informe nome, telefone, e-mail ou CPF.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<OccurrenceCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in OccurrenceCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Escolha uma categoria.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<Zone>(
              initialValue: _zone,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Região',
                helperText: 'Apenas a região ampla; nunca o endereço.',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final z in Zones.all)
                  DropdownMenuItem(value: z, child: Text(z.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _zone = v),
              validator: (v) => v == null ? 'Escolha a região.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 280,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: Validators.description,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Gravidade', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Baixa')),
                ButtonSegment(value: 2, label: Text('Média')),
                ButtonSegment(value: 3, label: Text('Alta')),
              ],
              selected: {_severity},
              onSelectionChanged: (s) => setState(() => _severity = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            FormField<bool>(
              initialValue: false,
              validator: (v) => v == true ? null : 'É preciso autorizar o uso anonimizado do relato.',
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: field.value ?? false,
                    onChanged: (v) => field.didChange(v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Autorizo o uso anonimizado deste relato para análise territorial.'),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Text(
                        field.errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.send),
              label: const Text('Enviar ocorrência'),
            ),
          ],
        ),
      ),
    );
  }
}
