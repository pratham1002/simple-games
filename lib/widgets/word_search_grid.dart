import 'dart:math';
import 'package:flutter/material.dart';
import 'package:senior_games/utils/word_search_generator.dart';

class WordSearchGrid extends StatefulWidget {
  final WordSearchPuzzle puzzle;
  final Function(String word) onWordFound;
  final Set<String> foundWords;
  final Map<String, MaterialColor> wordColors;

  const WordSearchGrid({
    super.key,
    required this.puzzle,
    required this.onWordFound,
    required this.foundWords,
    required this.wordColors,
  });

  @override
  State<WordSearchGrid> createState() => _WordSearchGridState();
}

class _WordSearchGridState extends State<WordSearchGrid> {
  Point? _startPoint;
  List<Point> _selectedPath = [];
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final gridSize = widget.puzzle.grid.length;
    final cellSize = _calculateCellSize(context, gridSize);

    return GestureDetector(
      onPanStart: (details) {
        final point = _getPointFromPosition(details.localPosition, cellSize, gridSize);
        if (point != null) {
          setState(() {
            _startPoint = point;
            _selectedPath = [point];
            _isDragging = true;
          });
        }
      },
      onPanUpdate: (details) {
        if (_startPoint == null) return;
        final point = _getPointFromPosition(details.localPosition, cellSize, gridSize);
        if (point != null) {
          setState(() {
            _selectedPath = _buildPath(_startPoint!, point);
          });
        }
      },
      onPanEnd: (details) {
        if (_selectedPath.isEmpty) {
          setState(() {
            _startPoint = null;
            _selectedPath = [];
            _isDragging = false;
          });
          return;
        }

        // Check if the selected path matches any placed word
        final selectedPoints = _selectedPath.toSet();
        final selectedLetters = _selectedPath
            .map((p) => widget.puzzle.grid[p.y][p.x])
            .join('');
        final reversedLetters = selectedLetters.split('').reversed.join('');

        for (final placedWord in widget.puzzle.placedWords) {
          if (widget.foundWords.contains(placedWord.word)) {
            continue; // Already found
          }

          final placedPoints = placedWord.points.toSet();
          final placedLetters = placedWord.word;

          // Check if selected path matches placed word (forward or backward)
          bool matches = false;
          if (selectedLetters == placedLetters ||
              reversedLetters == placedLetters) {
            // Check if points match exactly (allowing for reverse order)
            if (selectedPoints.length == placedPoints.length) {
              if (selectedPoints.containsAll(placedPoints) &&
                  placedPoints.containsAll(selectedPoints)) {
                matches = true;
              } else {
                // Check reverse order
                final reversedPath = _selectedPath.reversed.toList();
                final reversedPoints = reversedPath.toSet();
                if (reversedPoints.containsAll(placedPoints) &&
                    placedPoints.containsAll(reversedPoints)) {
                  matches = true;
                }
              }
            }
          }

          if (matches) {
            widget.onWordFound(placedWord.word);
            break;
          }
        }

        setState(() {
          _startPoint = null;
          _selectedPath = [];
          _isDragging = false;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: cellSize * gridSize,
              height: cellSize * gridSize,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  childAspectRatio: 1.0,
                ),
                itemCount: gridSize * gridSize,
                itemBuilder: (context, index) {
                  final row = index ~/ gridSize;
                  final col = index % gridSize;
                  final point = Point(col, row);
                  final letter = widget.puzzle.grid[row][col];
                  final isSelected = _selectedPath.contains(point);
                  final foundWordInfo = _getFoundWordInfo(point);

                  Color backgroundColor;
                  const Color textColor = Colors.black87;

                  if (foundWordInfo != null) {
                    // Use the word's color for background only
                    backgroundColor = foundWordInfo.color.shade200;
                  } else if (isSelected) {
                    backgroundColor = Colors.yellow.shade200;
                  } else {
                    backgroundColor = Colors.white;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: cellSize * 0.5,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateCellSize(BuildContext context, int gridSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 32.0;
    return min((screenWidth - padding) / gridSize, 40.0);
  }

  Point? _getPointFromPosition(Offset position, double cellSize, int gridSize) {
    final col = (position.dx / cellSize).floor();
    final row = (position.dy / cellSize).floor();

    if (col >= 0 && col < gridSize && row >= 0 && row < gridSize) {
      return Point(col, row);
    }
    return null;
  }

  List<Point> _buildPath(Point start, Point end) {
    final path = <Point>[];
    final dx = end.x - start.x;
    final dy = end.y - start.y;

    if (dx == 0 && dy == 0) {
      return [start];
    }

    // Determine direction
    int stepX = 0;
    int stepY = 0;
    if (dx != 0) stepX = dx.abs() ~/ dx;
    if (dy != 0) stepY = dy.abs() ~/ dy;

    // Build path in straight line
    int x = start.x;
    int y = start.y;
    final maxSteps = max(dx.abs(), dy.abs());

    for (int i = 0; i <= maxSteps; i++) {
      path.add(Point(x, y));
      if (x == end.x && y == end.y) break;
      x += stepX;
      y += stepY;
    }

    return path;
  }

  _FoundWordInfo? _getFoundWordInfo(Point point) {
    for (final word in widget.foundWords) {
      final placedWord = widget.puzzle.placedWords.firstWhere(
        (pw) => pw.word == word,
        orElse: () => widget.puzzle.placedWords.first,
      );
      if (placedWord.points.contains(point)) {
        final baseColor = widget.wordColors[word] ?? Colors.green;
        return _FoundWordInfo(word, baseColor);
      }
    }
    return null;
  }
}

class _FoundWordInfo {
  final String word;
  final MaterialColor color;

  _FoundWordInfo(this.word, this.color);
}

