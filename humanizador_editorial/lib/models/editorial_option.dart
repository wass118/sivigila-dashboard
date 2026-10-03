/// Opción editorial genérica (audiencia, objetivo, perfil de autor).
///
/// `promptHint` es la instrucción que se inyecta en el prompt; `label` es lo
/// que ve el usuario. Agregar una opción no requiere tocar pantallas.
class EditorialOption {
  const EditorialOption({
    required this.id,
    required this.label,
    required this.promptHint,
    this.description = '',
  });

  final String id;
  final String label;
  final String promptHint;
  final String description;

  @override
  bool operator ==(Object other) => other is EditorialOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Catálogo de opciones con búsqueda por id y valor por defecto.
class OptionCatalog {
  OptionCatalog(Iterable<EditorialOption> options)
      : _options = List.of(options);

  final List<EditorialOption> _options;

  List<EditorialOption> get all => List.unmodifiable(_options);

  EditorialOption byId(String? id) =>
      _options.firstWhere((o) => o.id == id, orElse: () => _options.first);

  bool contains(String? id) => _options.any((o) => o.id == id);

  void register(EditorialOption option) {
    _options.removeWhere((o) => o.id == option.id);
    _options.add(option);
  }
}
