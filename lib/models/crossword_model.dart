
class CrosswordModel {
  final List<List<Cell>> grid;
  final Map<String, List<Clue>> clues;
  bool isSolved = false;

  CrosswordModel({required this.grid, required this.clues});

  bool checkSolution() {
    bool allCorrect = true;
    for (var row in grid) {
      for (var cell in row) {
        if (cell.letter != ' ' && !cell.isCorrect) {
          allCorrect = false;
          break;
        }
      }
    }
    isSolved = allCorrect;
    return allCorrect;
  }
}

class Cell {
  final String letter;
  bool isCorrect = false;
  String currentLetter = '';
  int? number;

  Cell({
    required this.letter, 
    this.number,
  });

  bool get isEmpty => letter == ' ';
  bool get isFilledCorrectly => !isEmpty && letter.toLowerCase() == currentLetter.toLowerCase();

  void checkLetter() {
    isCorrect = isFilledCorrectly;
  }
}

class Clue {
  final String text;
  final String word;
  final int number;
  final bool isAcross;
  final int row;
  final int column;

  Clue({
    required this.text,
    required this.word,
    required this.number,
    required this.isAcross,
    required this.row,
    required this.column,
  });
}
