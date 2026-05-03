import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/lessons') || location.startsWith('/lesson-detail')) return 1;
    if (location.startsWith('/speech-practice')) return 2;
    if (location.startsWith('/sign-language') ||
        location.startsWith('/sign-detail') ||
        location.startsWith('/sign-camera')) {
      return 3;
    }
    if (location.startsWith('/progress')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/lessons');
        break;
      case 2:
        context.go('/speech-practice');
        break;
      case 3:
        context.go('/sign-language');
        break;
      case 4:
        context.go('/progress');
        break;
      case 5:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final int currentIndex = _selectedIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        color: const Color(0xFFEEF0F5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 1,
              color: const Color(0xFFD1D3D8),
            ),
            BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (int index) => _onTap(context, index),
              backgroundColor: const Color(0xFFEEF0F5),
              selectedItemColor: const Color(0xFF5B6BE8),
              unselectedItemColor: const Color(0xFF9A9EB5),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Lessons'),
                BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Practice'),
                BottomNavigationBarItem(icon: Icon(Icons.sign_language), label: 'Signs'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
