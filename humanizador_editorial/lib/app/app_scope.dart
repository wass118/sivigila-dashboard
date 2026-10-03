import 'package:flutter/widgets.dart';

import '../features/history/history_controller.dart';
import '../features/home/editor_controller.dart';
import '../features/settings/settings_controller.dart';
import 'app_services.dart';

/// Expone servicios y controladores al árbol de widgets. Las instancias no
/// cambian durante la vida de la app; los widgets escuchan cada controlador
/// con `ListenableBuilder`.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required this.settings,
    required this.history,
    required this.editor,
    required super.child,
  });

  final AppServices services;
  final SettingsController settings;
  final HistoryController history;
  final EditorController editor;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
