import 'package:flutter/material.dart';

import '../features/history/history_controller.dart';
import '../features/history/history_page.dart';
import '../features/home/editor_controller.dart';
import '../features/home/editor_page.dart';
import '../features/settings/settings_controller.dart';
import '../features/settings/settings_page.dart';
import 'app_scope.dart';
import 'app_services.dart';
import 'theme.dart';

/// Raíz de la aplicación: crea los controladores y el tema.
class HumanizadorApp extends StatefulWidget {
  const HumanizadorApp({super.key, required this.services});

  final AppServices services;

  @override
  State<HumanizadorApp> createState() => _HumanizadorAppState();
}

class _HumanizadorAppState extends State<HumanizadorApp> {
  late final SettingsController _settings = SettingsController(widget.services);
  late final HistoryController _history =
      HistoryController(widget.services.historyRepository);
  late final EditorController _editor = EditorController(
      services: widget.services,
      settingsController: _settings,
      historyController: _history);

  @override
  void initState() {
    super.initState();
    _settings.load();
    _history.load();
    _editor.loadPresets();
  }

  @override
  void dispose() {
    _editor.dispose();
    _history.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      settings: _settings,
      history: _history,
      editor: _editor,
      child: MaterialApp(
        title: 'Humanizador Editorial Técnico',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AppShell(),
      ),
    );
  }
}

/// Navegación: riel lateral en pantallas anchas, barra inferior en móvil.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const double railBreakpoint = 840;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    (Icons.edit_note_outlined, Icons.edit_note, 'Editor'),
    (Icons.history_outlined, Icons.history, 'Historial'),
    (Icons.settings_outlined, Icons.settings, 'Ajustes'),
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const EditorPage(),
      HistoryPage(onOpenInEditor: () => _go(0)),
      const SettingsPage(),
    ];
    final body = IndexedStack(index: _index, children: pages);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= AppShell.railBreakpoint) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _go,
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.spellcheck,
                      color: Theme.of(context).colorScheme.primary),
                ),
                destinations: [
                  for (final (icon, selected, label) in _destinations)
                    NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: Text(label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      }
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            for (final (icon, selected, label) in _destinations)
              NavigationDestination(
                  icon: Icon(icon), selectedIcon: Icon(selected), label: label),
          ],
        ),
      );
    });
  }
}
