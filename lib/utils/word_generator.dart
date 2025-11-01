import 'dart:math';
import 'package:senior_games/models/crossword_model.dart';

class WordGenerator {
  static final Map<String, String> _clueMap = {
    'apple': 'A common fruit that keeps the doctor away',
    'house': 'A place to call home',
    'table': 'You eat your meals on this furniture',
    'chair': 'You sit on this piece of furniture',
    'phone': 'A device used for communication',
    'book': 'Contains pages filled with stories or information',
    'garden': 'A place where flowers and vegetables grow',
    'family': 'Parents and children form this unit',
    'friend': 'Someone who supports and cares about you',
    'music': 'Pleasant sounds arranged in patterns',
    'water': 'Essential liquid for life',
    'earth': 'The planet we live on',
    'sunny': 'Bright and clear weather',
    'cloud': 'White fluffy thing in the sky',
    'river': 'A flowing body of water',
    'mountain': 'A tall natural elevation',
    'ocean': 'A vast body of salt water',
    'forest': 'A large area covered with trees',
    'beach': 'Sandy shore by the ocean',
    'island': 'Land surrounded by water',
    'bridge': 'Structure crossing a river',
    'castle': 'A large fortified building',
    'camera': 'Device for taking photos',
    'window': 'Opening in a wall with glass',
    'mirror': 'Reflective surface',
    'laptop': 'Portable computer',
    'pencil': 'Writing instrument',
    'paper': 'Material for writing',
    'coffee': 'Hot beverage',
    'bread': 'Baked food made from flour',
    'fruit': 'Edible part of a plant',
    'vegetable': 'Edible plant part',
    'animal': 'Living creature',
    'bird': 'Flying animal with feathers',
    'dog': 'Faithful pet',
    'cat': 'Independent pet',
    'tree': 'Tall plant with branches',
    'flower': 'Colorful plant part',
    'grass': 'Green ground covering',
    'happy': 'Feeling joy',
    'smile': 'Expression of happiness',
    'laugh': 'Sound of joy',
    'dance': 'Rhythmic movement',
    'sing': 'Produce musical sounds',
    'game': 'Activity for fun',
    'sport': 'Physical activity',
    'ball': 'Round object for play',
    'toy': 'Object for play',
    'color': 'Visual property',
    'rainbow': 'Colorful arc in sky',
  };
  
  static Future<void> loadWords() async {
    return;
  }

  static List<String> getRandomWords(int count) {
    final random = Random();
    final List<String> randomWords = [];
    final validWords = _clueMap.keys.toList();
    
    while (randomWords.length < count && validWords.isNotEmpty) {
      final index = random.nextInt(validWords.length);
      final word = validWords[index];
      if (!randomWords.contains(word)) {
        randomWords.add(word);
        validWords.removeAt(index);
      }
    }
    return randomWords;
  }

  /// Generate multiple crossword puzzles and return the best one based on density
  static Crossword? generateCrossword(List<String> words) {
    if (words.isEmpty) return null;
    
    // Work on a copy to avoid modifying the input
    final wordsCopy = List<String>.from(words);
    
    // Sort words by length (longest first) for better placement
    wordsCopy.sort((a, b) => b.length.compareTo(a.length));
    
    // Generate multiple puzzles and select the best one
    final random = Random();
    Crossword? bestCrossword;
    double bestDensity = 0.0;
    
    // Try generating multiple puzzles (fewer iterations for performance)
    for (int attempt = 0; attempt < 100; attempt++) {
      final puzzle = _generateSinglePuzzle(wordsCopy, random);
      if (puzzle != null) {
        final density = puzzle.density;
        if (density > bestDensity) {
          bestDensity = density;
          bestCrossword = puzzle;
        }
      }
    }
    
    return bestCrossword;
  }

  /// Generate a single crossword puzzle
  static Crossword? _generateSinglePuzzle(List<String> words, Random random) {
    if (words.isEmpty) return null;
    
    const width = 20;
    const height = 20;
    
    // Start with empty grid
    final grid = List.generate(height, (_) => List.filled(width, ' '));
    final placedWords = <PlacedWord>[];
    
    // Place the first word in the center
    final firstWord = words[0];
    if (firstWord.length > width || firstWord.length > height) {
      return null; // Word too long
    }
    
    final horizontal = random.nextBool();
    int startX, startY;
    
    if (horizontal) {
      startX = (width - firstWord.length) ~/ 2;
      startY = height ~/ 2;
    } else {
      startX = width ~/ 2;
      startY = (height - firstWord.length) ~/ 2;
    }
    
    if (!_placeWord(firstWord, startX, startY, horizontal, grid, placedWords,
        requireIntersection: false)) {
      return null;
    }
    
    // Try to place remaining words
    // Sort words by length (longest first) and by common characters for better placement
    final remainingWords = words.sublist(1);
    remainingWords.sort((a, b) => b.length.compareTo(a.length));
    
    // Try multiple times with shuffled order to get better placement
    var wordsToPlace = List<String>.from(remainingWords);
    for (int attempt = 0; attempt < 3 && wordsToPlace.isNotEmpty; attempt++) {
      wordsToPlace.shuffle(random);
      final stillToPlace = <String>[];
      for (final word in wordsToPlace) {
        if (!_tryPlaceWord(word, grid, placedWords, random)) {
          stillToPlace.add(word);
        }
      }
      wordsToPlace = stillToPlace;
    }
    
    // Need at least 2 words for a valid crossword
    if (placedWords.length < 2) {
      return null;
    }
    
    // Trim grid to actual used area
    final trimmed = _trimGrid(grid, placedWords);
    final trimmedGrid = trimmed['grid'] as List<List<String>>;
    final offsetX = trimmed['offsetX'] as int;
    final offsetY = trimmed['offsetY'] as int;
    
    // Adjust word positions
    for (final word in placedWords) {
      word.x -= offsetX;
      word.y -= offsetY;
    }
    
    // Generate clues
    final clues = _generateClues(placedWords);
    
    return Crossword(trimmedGrid, clues);
  }

  /// Try to place a word in the puzzle by finding intersections
  static bool _tryPlaceWord(
    String word,
    List<List<String>> grid,
    List<PlacedWord> placedWords,
    Random random,
  ) {
    // Find all possible positions where this word can intersect
    final possiblePositions = <WordPlacement>[];
    
    for (final placedWord in placedWords) {
      // Check each character in the word we're trying to place
      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        
        // Check each character in the placed word (case-insensitive)
        for (int j = 0; j < placedWord.word.length; j++) {
          if (placedWord.word[j].toLowerCase() == char.toLowerCase()) {
            // Potential intersection found
            final horizontal = !placedWord.horizontal;
            int newX, newY;
            
            if (horizontal) {
              newX = placedWord.x + j - i;
              newY = placedWord.y;
            } else {
              newX = placedWord.x;
              newY = placedWord.y + j - i;
            }
            
            if (_canPlaceWord(word, newX, newY, horizontal, grid)) {
              possiblePositions.add(WordPlacement(newX, newY, horizontal));
            }
          }
        }
      }
    }
    
    if (possiblePositions.isEmpty) {
      return false;
    }
    
    // Randomly select one of the possible positions
    final selected = possiblePositions[random.nextInt(possiblePositions.length)];
    return _placeWord(word, selected.x, selected.y, selected.horizontal, grid, placedWords);
  }

  /// Check if a word can be placed at the given position
  static bool _canPlaceWord(
    String word,
    int x,
    int y,
    bool horizontal,
    List<List<String>> grid, {
    bool requireIntersection = true,
  }) {
    final width = grid[0].length;
    final height = grid.length;
    
    // Check bounds
    if (horizontal) {
      if (x < 0 || x + word.length > width) return false;
      if (y < 0 || y >= height) return false;
    } else {
      if (x < 0 || x >= width) return false;
      if (y < 0 || y + word.length > height) return false;
    }
    
    // Track whether we intersect with existing word if required
    bool hasIntersection = !requireIntersection;
    
    // Check each position where we want to place the word
    for (int i = 0; i < word.length; i++) {
      final checkX = horizontal ? x + i : x;
      final checkY = horizontal ? y : y + i;
      
      final existingChar = grid[checkY][checkX];
      
      if (existingChar == ' ') {
        // Cell is empty, check adjacent cells to prevent parallel words
        if (horizontal) {
          // Check cells above and below
          if (checkY > 0 && grid[checkY - 1][checkX] != ' ') return false;
          if (checkY < height - 1 && grid[checkY + 1][checkX] != ' ') return false;
        } else {
          // Check cells left and right
          if (checkX > 0 && grid[checkY][checkX - 1] != ' ') return false;
          if (checkX < width - 1 && grid[checkY][checkX + 1] != ' ') return false;
        }
      } else {
        // Cell is filled - check if it matches (case-insensitive)
        if (existingChar.toLowerCase() != word[i].toLowerCase()) {
          return false; // Different character
        }
        // Matching character - this is an intersection
        hasIntersection = true;
      }
    }
    
    // Must have at least one intersection if required
    if (requireIntersection && !hasIntersection) return false;
    
    // Check ends of word - must be empty
    if (horizontal) {
      if (x > 0 && grid[y][x - 1] != ' ') return false;
      if (x + word.length < width && grid[y][x + word.length] != ' ') return false;
    } else {
      if (y > 0 && grid[y - 1][x] != ' ') return false;
      if (y + word.length < height && grid[y + word.length][x] != ' ') return false;
    }
    
    // Additional check: ensure we're not creating invalid intersections
    // (word should intersect properly with existing words)
    
    return true;
  }

  /// Place a word in the grid
  static bool _placeWord(
    String word,
    int x,
    int y,
    bool horizontal,
    List<List<String>> grid,
    List<PlacedWord> placedWords, {
    bool requireIntersection = true,
  }) {
    if (!_canPlaceWord(word, x, y, horizontal, grid,
        requireIntersection: requireIntersection)) {
      return false;
    }
    
    if (horizontal) {
      for (int i = 0; i < word.length; i++) {
        // Use uppercase for consistency
        grid[y][x + i] = word[i].toUpperCase();
      }
    } else {
      for (int i = 0; i < word.length; i++) {
        // Use uppercase for consistency
        grid[y + i][x] = word[i].toUpperCase();
      }
    }
    
    placedWords.add(PlacedWord(word, x, y, horizontal));
    return true;
  }

  /// Trim grid to actual used area
  static Map<String, dynamic> _trimGrid(
    List<List<String>> grid,
    List<PlacedWord> placedWords,
  ) {
    int minX = grid[0].length;
    int maxX = 0;
    int minY = grid.length;
    int maxY = 0;
    
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        if (grid[y][x] != ' ') {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    
    // Validate that we found used cells
    if (minX > maxX || minY > maxY) {
      // No cells used, return original grid
      return {
        'grid': grid,
        'offsetX': 0,
        'offsetY': 0,
      };
    }
    
    // Add padding
    minX = (minX - 1).clamp(0, grid[0].length - 1);
    minY = (minY - 1).clamp(0, grid.length - 1);
    maxX = (maxX + 1).clamp(0, grid[0].length - 1);
    maxY = (maxY + 1).clamp(0, grid.length - 1);
    
    // Ensure valid dimensions
    if (maxX < minX) maxX = minX;
    if (maxY < minY) maxY = minY;
    
    // Create trimmed grid
    final trimmedGrid = List.generate(
      maxY - minY + 1,
      (y) => List.generate(
        maxX - minX + 1,
        (x) => grid[y + minY][x + minX],
      ),
    );
    
    return {
      'grid': trimmedGrid,
      'offsetX': minX,
      'offsetY': minY,
    };
  }

  /// Generate clues for placed words
  static Map<String, List<Clue>> _generateClues(List<PlacedWord> words) {
    final Map<String, List<Clue>> clues = {
      'Across': [],
      'Down': [],
    };
    
    // Sort words by position (top to bottom, left to right)
    words.sort((a, b) {
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });
    
    // Group words by their starting position for numbering
    final Map<String, int> positionToNumber = {};
    int clueNumber = 1;
    
    for (final word in words) {
      final key = '${word.x},${word.y}';
      if (!positionToNumber.containsKey(key)) {
        positionToNumber[key] = clueNumber++;
      }
    }
    
    // Create clues
    for (final word in words) {
      final key = '${word.x},${word.y}';
      final number = positionToNumber[key] ?? 1;
      final clueText = _clueMap[word.word.toLowerCase()] ?? 'Definition for ${word.word}';
      final clue = Clue(
        text: '$number. $clueText',
        word: word.word,
        number: number,
        isAcross: word.horizontal,
        row: word.y,
        column: word.x,
      );
      
      if (word.horizontal) {
        clues['Across']!.add(clue);
      } else {
        clues['Down']!.add(clue);
      }
    }
    
    // Sort clues by number
    clues['Across']!.sort((a, b) => a.number.compareTo(b.number));
    clues['Down']!.sort((a, b) => a.number.compareTo(b.number));
    
    return clues;
  }
}

class Crossword {
  final List<List<String>> grid;
  final Map<String, List<Clue>> clues;
  
  Crossword(this.grid, this.clues);
  
  /// Calculate density (ratio of letters to total cells)
  double get density {
    int letters = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell != ' ') {
          letters++;
        }
      }
    }
    return letters / (grid.length * (grid.isNotEmpty ? grid[0].length : 1));
  }
}

class PlacedWord {
  final String word;
  int x;
  int y;
  final bool horizontal;
  
  PlacedWord(this.word, this.x, this.y, this.horizontal);
}

class WordPlacement {
  final int x;
  final int y;
  final bool horizontal;
  
  WordPlacement(this.x, this.y, this.horizontal);
}

