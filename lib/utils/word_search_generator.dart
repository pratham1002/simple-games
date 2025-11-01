import 'dart:math';

class WordSearchGenerator {
  static final List<String> _wordList = [
    // Animals
    'CAT',
    'DOG',
    'BIRD',
    'FISH',
    'BEAR',
    'LION',
    'TIGER',
    'EAGLE',
    'SHARK',
    'WHALE',
    // Fruits
    'APPLE',
    'BANANA',
    'ORANGE',
    'GRAPE',
    'MANGO',
    'LEMON',
    'PEACH',
    'CHERRY',
    // Objects
    'BOOK',
    'CHAIR',
    'TABLE',
    'PHONE',
    'LIGHT',
    'CLOCK',
    'HOUSE',
    'CAR',
    'TREE',
  ];

  static List<String> getRandomWords(int count, Random random) {
    final shuffled = List<String>.from(_wordList)..shuffle(random);
    return shuffled.take(count).map((word) => word.toUpperCase()).toList();
  }

  static WordSearchPuzzle generate({
    int gridSize = 10,
    int wordCount = 8,
    int maxAttempts = 15,
  }) {
    final seedRandom = Random(DateTime.now().microsecondsSinceEpoch);
    final baseWords = getRandomWords(wordCount, seedRandom);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final attemptRandom = Random(seedRandom.nextInt(1 << 32));
      final orderedWords = List<String>.from(baseWords)
        ..shuffle(attemptRandom)
        ..sort((a, b) => b.length.compareTo(a.length));

      final puzzle = _attemptGenerate(orderedWords, gridSize, attemptRandom);
      if (puzzle != null) {
        return puzzle;
      }
    }

    // Fallback to legacy placement to ensure a puzzle is produced
    final fallbackRandom = Random(seedRandom.nextInt(1 << 32));
    return _legacyGenerate(baseWords, gridSize, fallbackRandom);
  }

  static WordSearchPuzzle _legacyGenerate(
    List<String> words,
    int gridSize,
    Random random,
  ) {
    final grid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, ' '),
    );
    final placedWords = <PlacedWord>[];

    final directions = List<Direction>.from(_directions);

    for (final word in words) {
      bool placed = false;
      int attempts = 0;
      const maxAttempts = 100;

      while (!placed && attempts < maxAttempts) {
        attempts++;
        directions.shuffle(random);
        final direction = directions.first;
        final startX = random.nextInt(gridSize);
        final startY = random.nextInt(gridSize);

        if (_calculatePlacement(grid, word, startX, startY, direction) >= 0) {
          _placeWord(grid, word, startX, startY, direction);
          placedWords.add(PlacedWord(
            word: word,
            startX: startX,
            startY: startY,
            direction: direction,
          ));
          placed = true;
        }
      }
    }

    _fillGrid(grid, random);

    final usedWords = placedWords.map((pw) => pw.word).toList();

    return WordSearchPuzzle(
      grid: grid,
      words: usedWords,
      placedWords: placedWords,
    );
  }

  static WordSearchPuzzle? _attemptGenerate(
    List<String> words,
    int gridSize,
    Random random,
  ) {
    final grid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, ' '),
    );
    final placedWords = <PlacedWord>[];

    for (int index = 0; index < words.length; index++) {
      final word = words[index];
      final directions = List<Direction>.from(_directions)..shuffle(random);
      final candidates = _findCandidates(grid, word, directions, random);

      if (candidates.isEmpty) {
        return null; // restart puzzle generation
      }

      // Prefer placements with overlaps when possible
      List<_PlacementCandidate> prioritized = candidates;
      if (placedWords.isNotEmpty) {
        final overlapCandidates =
            candidates.where((candidate) => candidate.overlap > 0).toList();
        if (overlapCandidates.isNotEmpty) {
          prioritized = overlapCandidates;
        }
      }

      prioritized.sort((a, b) => b.overlap.compareTo(a.overlap));
      final topCount = prioritized.length < 3 ? prioritized.length : 3;
      final selectionPool = prioritized.take(topCount).toList();
      final chosen = selectionPool[random.nextInt(selectionPool.length)];

      _placeWord(
        grid,
        word,
        chosen.startX,
        chosen.startY,
        chosen.direction,
      );
      placedWords.add(PlacedWord(
        word: word,
        startX: chosen.startX,
        startY: chosen.startY,
        direction: chosen.direction,
      ));
    }

    _fillGrid(grid, random);

    final usedWords = placedWords.map((pw) => pw.word).toList();

    return WordSearchPuzzle(
      grid: grid,
      words: usedWords,
      placedWords: placedWords,
    );
  }

  static List<_PlacementCandidate> _findCandidates(
    List<List<String>> grid,
    String word,
    List<Direction> directions,
    Random random,
  ) {
    final gridSize = grid.length;
    final candidates = <_PlacementCandidate>[];

    for (final direction in directions) {
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          final endX = x + direction.dx * (word.length - 1);
          final endY = y + direction.dy * (word.length - 1);
          if (endX < 0 || endX >= gridSize || endY < 0 || endY >= gridSize) {
            continue;
          }

          final overlap = _calculatePlacement(grid, word, x, y, direction);
          if (overlap >= 0) {
            candidates.add(_PlacementCandidate(
              startX: x,
              startY: y,
              direction: direction,
              overlap: overlap,
              randomness: random.nextDouble(),
            ));
          }
        }
      }
    }

    candidates.shuffle(random);
    return candidates;
  }

  static int _calculatePlacement(
    List<List<String>> grid,
    String word,
    int startX,
    int startY,
    Direction direction,
  ) {
    final gridSize = grid.length;
    int overlap = 0;

    for (int i = 0; i < word.length; i++) {
      final x = startX + direction.dx * i;
      final y = startY + direction.dy * i;

      if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
        return -1;
      }

      final existingChar = grid[y][x];
      if (existingChar != ' ' && existingChar != word[i]) {
        return -1;
      }

      if (existingChar == word[i]) {
        overlap++;
      }
    }

    return overlap;
  }

  static void _placeWord(
    List<List<String>> grid,
    String word,
    int startX,
    int startY,
    Direction direction,
  ) {
    for (int i = 0; i < word.length; i++) {
      final x = startX + direction.dx * i;
      final y = startY + direction.dy * i;
      grid[y][x] = word[i];
    }
  }

  static void _fillGrid(List<List<String>> grid, Random random) {
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        if (grid[y][x] == ' ') {
          grid[y][x] = _randomFillLetter(random);
        }
      }
    }
  }

  static String _randomFillLetter(Random random) {
    final index = random.nextInt(_fillLetterFrequency.length);
    return _fillLetterFrequency[index];
  }

  static const String _fillLetterFrequency =
      'EEEEEEEEEEEEEEEEEEEEEEEEAAAAAAAIIIIIIIIOOOOOOOO'
      'NNNNNNRRRRRRSSSSSSTTTTTLLLLCCCCCUDDDDMMMMHUUU';

  static final List<Direction> _directions = [
    const Direction(1, 0),
    const Direction(-1, 0),
    const Direction(0, 1),
    const Direction(0, -1),
    const Direction(1, 1),
    const Direction(-1, -1),
    const Direction(1, -1),
    const Direction(-1, 1),
  ];
}

class WordSearchPuzzle {
  final List<List<String>> grid;
  final List<String> words;
  final List<PlacedWord> placedWords;

  WordSearchPuzzle({
    required this.grid,
    required this.words,
    required this.placedWords,
  });
}

class PlacedWord {
  final String word;
  final int startX;
  final int startY;
  final Direction direction;

  PlacedWord({
    required this.word,
    required this.startX,
    required this.startY,
    required this.direction,
  });

  List<Point> get points {
    final points = <Point>[];
    for (int i = 0; i < word.length; i++) {
      points.add(Point(
        startX + direction.dx * i,
        startY + direction.dy * i,
      ));
    }
    return points;
  }
}

class Direction {
  final int dx;
  final int dy;

  const Direction(this.dx, this.dy);
}

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class _PlacementCandidate {
  final int startX;
  final int startY;
  final Direction direction;
  final int overlap;
  final double randomness;

  _PlacementCandidate({
    required this.startX,
    required this.startY,
    required this.direction,
    required this.overlap,
    required this.randomness,
  });
}

