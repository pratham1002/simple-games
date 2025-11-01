
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senior_games/models/crossword_model.dart';
import 'package:senior_games/utils/word_generator.dart';
import 'package:senior_games/widgets/clue_list.dart';
import 'package:senior_games/widgets/crossword_grid.dart';

class CrosswordScreen extends StatelessWidget {
  const CrosswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CrosswordState(),
      child: const CrosswordView(),
    );
  }
}

class CrosswordView extends StatefulWidget {
  const CrosswordView({super.key});

  @override
  State<CrosswordView> createState() => _CrosswordViewState();
}

class _CrosswordViewState extends State<CrosswordView> {
  void _showCompletionDialog(CrosswordState state) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Great job! You solved the puzzle!'),
        duration: Duration(seconds: 3),
      ),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Puzzle Complete'),
          content: const Text(
            'You filled in every word correctly! What would you like to do next?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Go back to home screen
              },
              child: const Text('Go to Home Page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                state.generateNewCrossword();
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
        title: const Text('Crossword'),
      ),
      body: Consumer<CrosswordState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.crossword == null) {
            return const Center(child: Text('Failed to generate crossword'));
          }
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: CrosswordGrid(
                  crossword: state.crossword!,
                  onSolved: () => _showCompletionDialog(state),
                ),
              ),
              Expanded(
                flex: 2,
                child: ClueList(clues: state.crossword!.clues),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<CrosswordState>(context, listen: false)
                        .generateNewCrossword();
                  },
                  child: const Text('New Puzzle'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CrosswordState extends ChangeNotifier {
  CrosswordModel? _crossword;
  bool _isLoading = false;

  CrosswordModel? get crossword => _crossword;
  bool get isLoading => _isLoading;

  CrosswordState() {
    _init();
  }

  Future<void> _init() async {
    await WordGenerator.loadWords();
    generateNewCrossword();
  }

  Future<void> generateNewCrossword() async {
    _isLoading = true;
    _crossword = null;
    notifyListeners();

    Crossword? generatedCrossword;
    
    // Try multiple times with different word sets
    for (int i = 0; i < 20; i++) {
      try {
        final words = WordGenerator.getRandomWords(6); // Reduced to 6 for better success rate
        if (words.length < 2) continue;
        
        generatedCrossword = await compute(WordGenerator.generateCrossword, words);

        if (generatedCrossword != null && generatedCrossword.grid.isNotEmpty) {
          final grid = generatedCrossword.grid.map((row) => row.map((letter) => Cell(letter: letter)).toList()).toList();
        
          // Validate grid dimensions
          if (grid.isEmpty || grid[0].isEmpty) continue;
          
          // Add cell numbers based on clues
          for (var direction in generatedCrossword.clues.keys) {
            for (var clue in generatedCrossword.clues[direction]!) {
              if (clue.row < grid.length && clue.column < grid[clue.row].length) {
                grid[clue.row][clue.column].number = clue.number;
              }
            }
          }
        
          _crossword = CrosswordModel(grid: grid, clues: generatedCrossword.clues);
          break;
        }
      } catch (e) {
        // Continue trying if there's an error
        continue;
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
