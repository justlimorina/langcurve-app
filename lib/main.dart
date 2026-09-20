import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/theme_provider.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/dictionary/dictionary_view.dart';
import 'views/notebook/notebook_view.dart';
import 'views/practice/practice_view.dart';
import 'widgets/responsive_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Windows desktop SQLite
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const LangCurveApp(),
    ),
  );
}

class LangCurveApp extends StatelessWidget {
  const LangCurveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'LangCurve',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardView(),
      DictionaryView(
        onNavigateToNotebook: () => _navigateToIndex(2),
      ),
      NotebookView(
        onNavigateToDictionary: () => _navigateToIndex(1),
      ),
      PracticeView(
        onNavigateToDictionary: () => _navigateToIndex(1),
      ),
    ];

    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onNavigationChanged: _navigateToIndex,
      pages: pages,
    );
  }
}
