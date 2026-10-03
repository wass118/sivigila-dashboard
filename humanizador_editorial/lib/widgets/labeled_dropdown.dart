import 'package:flutter/material.dart';

class DropdownItem<T> {
  const DropdownItem(this.value, this.label, {this.subtitle});
  final T value;
  final String label;
  final String? subtitle;
}

/// Desplegable con etiqueta, controlado por `value` (se actualiza al
/// aplicar presets sin reconstruir claves).
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.helper,
    this.hint,
  });

  final String label;
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? helper;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hasValue = items.any((i) => i.value == value);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: hasValue ? value : null,
          isExpanded: true,
          isDense: true,
          hint: hint == null ? null : Text(hint!),
          borderRadius: BorderRadius.circular(8),
          onChanged: onChanged == null
              ? null
              : (v) {
                  if (v != null) onChanged!(v);
                },
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item.value,
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }
}
