
import 'package:flutter/material.dart';
import 'package:senior_games/models/crossword_model.dart';

class ClueList extends StatelessWidget {
  final Map<String, List<Clue>> clues;

  const ClueList({super.key, required this.clues});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildClueList('Across', clues['Across'] ?? []),
          ),
          Expanded(
            child: _buildClueList('Down', clues['Down'] ?? []),
          ),
        ],
      ),
    );
  }

  Widget _buildClueList(String title, List<Clue> clueList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: clueList.length,
            itemBuilder: (context, index) {
              final clue = clueList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  clue.text,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
