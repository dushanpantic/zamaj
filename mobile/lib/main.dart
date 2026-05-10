import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zamaj',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
