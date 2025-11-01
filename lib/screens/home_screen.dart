
import 'package:flutter/material.dart';
import 'package:senior_games/screens/crossword_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senior Fun Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings screen
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrosswordScreen(),
                  ),
                );
              },
              child: const Text('🧩 Crossword'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: null, // Disabled
              child: const Text('🎨 Ball Sort (coming soon)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: null, // Disabled
              child: const Text('🍉 Fruit Slice (coming soon)'),
            ),
          ],
        ),
      ),
    );
  }
}
