
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

class CrosswordView extends StatelessWidget {
  const CrosswordView({super.key});

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
                child: CrosswordGrid(crossword: state.crossword!),
              ),
              ClueList(clues: state.crossword!.clues),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<CrosswordState>(context, listen: false).generateNewCrossword();
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

    for (int i = 0; i < 10; i++) {
      final words = WordGenerator.getRandomWords(8);
      final generatedCrossword = await compute(WordGenerator.generateCrossword, words);

      if (generatedCrossword != null) {
        final grid = generatedCrossword.grid.map((row) => row.map((letter) => Cell(letter: letter)).toList()).toList();
      
      // Add cell numbers based on clues
      for (var direction in generatedCrossword.clues.keys) {
        for (var clue in generatedCrossword.clues[direction]!) {
          grid[clue.row][clue.column].number = clue.number;
        }
      }
      
      _crossword = CrosswordModel(grid: grid, clues: generatedCrossword.clues);
      break;
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
