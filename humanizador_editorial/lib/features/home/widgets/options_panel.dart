import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../models/domain_profile.dart';
import '../../../models/editorial_preset.dart';
import '../../../models/editorial_request.dart';
import '../../../models/intensity.dart';
import '../../../widgets/labeled_dropdown.dart';
import '../../../widgets/section_card.dart';

/// Selectores de dominio, audiencia, objetivo, perfil de autor, intensidad
/// y presets. Se construyen a partir de los catálogos: añadir una opción no
/// requiere cambiar este widget.
class OptionsPanel extends StatelessWidget {
  const OptionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final editor = scope.editor;
    final services = scope.services;
    final o = editor.options;
    final enabled = !editor.isBusy;
    final detected = editor.analysis?.effectiveDomain;

    void update(EditorialOptions next) => editor.updateOptions(next);

    final fields = <Widget>[
      LabeledDropdown<String>(
        label: 'Dominio',
        value: o.domainId,
        helper: o.domainId == DomainRegistry.autoId && detected != null
            ? 'Detectado: ${detected.label}'
            : null,
        items: [
          const DropdownItem(DomainRegistry.autoId, 'Detección automática'),
          for (final d in services.domains.all) DropdownItem(d.id, d.label),
        ],
        onChanged: enabled ? (v) => update(o.copyWith(domainId: v)) : null,
      ),
      LabeledDropdown<String>(
        label: 'Audiencia',
        value: o.audienceId,
        items: [
          for (final a in services.audiences.all) DropdownItem(a.id, a.label),
        ],
        onChanged: enabled ? (v) => update(o.copyWith(audienceId: v)) : null,
      ),
      LabeledDropdown<String>(
        label: 'Objetivo editorial',
        value: o.goalId,
        helper: o.goalId == EditorialOptions.reviewOnlyGoalId
            ? 'Este objetivo no genera nueva versión.'
            : null,
        items: [
          for (final g in services.goals.all) DropdownItem(g.id, g.label),
        ],
        onChanged: enabled ? (v) => update(o.copyWith(goalId: v)) : null,
      ),
      LabeledDropdown<String>(
        label: 'Perfil de autor',
        value: o.authorProfileId,
        items: [
          for (final a in services.authors.all) DropdownItem(a.id, a.label),
        ],
        onChanged:
            enabled ? (v) => update(o.copyWith(authorProfileId: v)) : null,
      ),
    ];

    return SectionCard(
      title: 'Configuración del análisis',
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PresetRow(enabled: enabled),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 520;
            if (!twoColumns) {
              return Column(
                children: [
                  for (final f in fields)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12), child: f),
                ],
              );
            }
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final f in fields) SizedBox(width: width, child: f)],
            );
          }),
          const SizedBox(height: 12),
          Text('Intensidad de intervención',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in Intensity.values)
                ChoiceChip(
                  label: Text(i.label),
                  selected: o.intensity == i,
                  tooltip: i.description,
                  onSelected: enabled
                      ? (_) => update(o.copyWith(intensity: i))
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(o.effectiveIntensity.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (o.extraStyleRules.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Reglas del preset: ${o.extraStyleRules.join(' · ')}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.enabled});
  final bool enabled;

  Future<void> _saveDialog(BuildContext context) async {
    final editor = AppScope.of(context).editor;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar configuración como preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre del preset'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await editor.saveCurrentAsPreset(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    final selected = editor.presets
        .where((p) => p.id == editor.presetId)
        .cast<EditorialPreset?>()
        .firstWhere((_) => true, orElse: () => null);
    return Row(
      children: [
        Expanded(
          child: LabeledDropdown<String>(
            label: 'Preset',
            hint: 'Ninguno (configuración manual)',
            value: editor.presetId,
            items: [
              for (final p in editor.presets)
                DropdownItem(p.id, p.builtIn ? p.name : '${p.name} (propio)'),
            ],
            onChanged: enabled
                ? (id) => editor
                    .applyPreset(editor.presets.firstWhere((p) => p.id == id))
                : null,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Guardar configuración actual como preset',
          onPressed: enabled ? () => _saveDialog(context) : null,
          icon: const Icon(Icons.bookmark_add_outlined),
        ),
        if (selected != null && !selected.builtIn)
          IconButton(
            tooltip: 'Eliminar preset',
            onPressed: enabled ? () => editor.deletePreset(selected.id) : null,
            icon: const Icon(Icons.bookmark_remove_outlined),
          ),
      ],
    );
  }
}
