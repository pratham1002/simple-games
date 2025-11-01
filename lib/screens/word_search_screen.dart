import 'package:flutter/material.dart';
import 'package:senior_games/utils/word_search_generator.dart';
import 'package:senior_games/widgets/word_search_grid.dart';

class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  late WordSearchPuzzle _puzzle;
  final Set<String> _foundWords = {};
  
  // Color palette for word blocks
  static final List<Color> _wordColors = [
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.orange.shade100,
    Colors.purple.shade100,
    Colors.pink.shade100,
    Colors.teal.shade100,
    Colors.amber.shade100,
    Colors.cyan.shade100,
    Colors.indigo.shade100,
    Colors.lime.shade100,
  ];
  
  static final List<Color> _borderColors = [
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.pink.shade400,
    Colors.teal.shade400,
    Colors.amber.shade400,
    Colors.cyan.shade400,
    Colors.indigo.shade400,
    Colors.lime.shade400,
  ];
  
  static final List<MaterialColor> _baseColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _generateNewPuzzle();
  }

  void _generateNewPuzzle() {
    setState(() {
      _foundWords.clear();
      _puzzle = WordSearchGenerator.generate(gridSize: 10, wordCount: 8);
    });
  }

  Map<String, MaterialColor> _getWordColorMap() {
    final colorMap = <String, MaterialColor>{};
    for (int i = 0; i < _puzzle.words.length; i++) {
      final word = _puzzle.words[i];
      final colorIndex = i % _baseColors.length;
      // Use the base MaterialColor so we can use shade200/shade900
      colorMap[word] = _baseColors[colorIndex];
    }
    return colorMap;
  }

  void _onWordFound(String word) {
    setState(() {
      _foundWords.add(word);
    });

    if (_foundWords.length == _puzzle.words.length) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Well done!'),
          content: const Text('You completed this puzzle 🎉'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Menu'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateNewPuzzle();
              },
              child: const Text('New Puzzle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateNewPuzzle,
            tooltip: 'New Puzzle',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxHeight > constraints.maxWidth;

          if (isPortrait) {
            return Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: WordSearchGrid(
                      puzzle: _puzzle,
                      foundWords: _foundWords,
                      onWordFound: _onWordFound,
                      wordColors: _getWordColorMap(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _buildWordList(),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: WordSearchGrid(
                      puzzle: _puzzle,
                      foundWords: _foundWords,
                      onWordFound: _onWordFound,
                      wordColors: _getWordColorMap(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildWordList(),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildWordList() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: _puzzle.words.asMap().entries.map((entry) {
        final index = entry.key;
        final word = entry.value;
        final isFound = _foundWords.contains(word);
        final colorIndex = index % _wordColors.length;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          decoration: BoxDecoration(
            color: isFound 
                ? Colors.grey.shade300 
                : _wordColors[colorIndex],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isFound 
                  ? Colors.grey.shade400 
                  : _borderColors[colorIndex],
              width: 2.0,
            ),
          ),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              decoration: isFound
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: isFound ? Colors.grey.shade600 : Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }
}

