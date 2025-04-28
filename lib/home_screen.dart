import 'package:flutter/material.dart';
import 'package:map/unit_list_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const WelcomePage(),
      MapScreen(token: widget.token),
      UnitListScreen(token: widget.token), // دیگه const نمیذاری
    ];

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'خانه'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'نقشه'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'واحدها'),
        ],
      ),
    );
  }
}


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'خوش آمدید!',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
