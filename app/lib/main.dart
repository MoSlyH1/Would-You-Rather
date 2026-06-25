import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/game_screen.dart';
import 'screens/submit_screen.dart';
import 'screens/admin_screen.dart';

void main() => runApp(const WyrApp());

class WyrApp extends StatelessWidget {
  const WyrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Would You Rather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  late final List<Widget> _pages = const [
    GameScreen(),
    SubmitScreen(),
    AdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: AppTheme.pageGradient,
        child: SafeArea(
          bottom: false,
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.card,
        indicatorColor: AppTheme.crimson.withOpacity(0.25),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(Icons.sports_esports),
              label: 'Play'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Submit'),
          NavigationDestination(
              icon: Icon(Icons.lock_outline),
              selectedIcon: Icon(Icons.lock),
              label: 'Admin'),
        ],
      ),
    );
  }
}
