
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senior_games/models/crossword_model.dart';

class CrosswordGrid extends StatefulWidget {
  final CrosswordModel crossword;
  final VoidCallback? onSolved;

  const CrosswordGrid({super.key, required this.crossword, this.onSolved});

  @override
  State<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends State<CrosswordGrid> {
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _isSolved = widget.crossword.isSolved;
  }

  @override
  void didUpdateWidget(CrosswordGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.crossword != widget.crossword ||
        oldWidget.crossword.isSolved != widget.crossword.isSolved) {
      setState(() {
        _isSolved = widget.crossword.isSolved;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowCount = widget.crossword.grid.length;
        final colCount = rowCount > 0 ? widget.crossword.grid[0].length : 0;

        if (rowCount == 0 || colCount == 0) {
          return const SizedBox.shrink();
        }

        final cellSize = min(
          constraints.maxWidth / colCount,
          constraints.maxHeight / rowCount,
        );

        final boardWidth = cellSize * colCount;
        final boardHeight = cellSize * rowCount;

        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: AbsorbPointer(
                  absorbing: _isSolved,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colCount,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: rowCount * colCount,
                    itemBuilder: (context, index) {
                      final row = index ~/ colCount;
                      final col = index % colCount;
                      if (row >= rowCount || col >= colCount) {
                        return const SizedBox.shrink();
                      }

                      final cell = widget.crossword.grid[row][col];

                      if (cell.isEmpty) {
                        return Container(
                          color: Colors.black87,
                        );
                      }

                      final bool hasInput = cell.currentLetter.isNotEmpty;
                      final bool isCorrect = cell.isCorrect;

                      final Color backgroundColor;
                      final Color borderColor;
                      final Color textColor;

                      if (!hasInput) {
                        backgroundColor = Colors.white;
                        borderColor = Colors.black54;
                        textColor = Colors.black87;
                      } else if (isCorrect) {
                        backgroundColor = Colors.green.shade100;
                        borderColor = Colors.green.shade700;
                        textColor = Colors.green.shade900;
                      } else {
                        backgroundColor = Colors.red.shade100;
                        borderColor = Colors.red.shade700;
                        textColor = Colors.red.shade900;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(color: borderColor),
                        ),
                        child: Stack(
                          children: [
                            if (cell.number != null)
                              Positioned(
                                left: 2,
                                top: 2,
                                child: Text(
                                  '${cell.number}',
                                  style: TextStyle(
                                    fontSize: cellSize * 0.2,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            Center(
                              child: TextField(
                                key: ValueKey('cell_${row}_$col'),
                                textAlign: TextAlign.center,
                                textCapitalization:
                                    TextCapitalization.characters,
                                cursorColor: Colors.blueGrey,
                                style: TextStyle(
                                  fontSize: cellSize * 0.55,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[A-Za-z]'),
                                  ),
                                  UpperCaseTextFormatter(),
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                onChanged: (value) {
                                  final normalized = value.trim().toUpperCase();
                                  var notifySolved = false;
                                  setState(() {
                                    cell.currentLetter = normalized;
                                    cell.checkLetter();
                                    final alreadySolved =
                                        widget.crossword.isSolved;
                                    final solved =
                                        widget.crossword.checkSolution();
                                    _isSolved = solved;
                                    if (solved && !alreadySolved) {
                                      notifySolved = true;
                                    }
                                  });

                                  if (notifySolved) {
                                    FocusScope.of(context).unfocus();
                                    widget.onSolved?.call();
                                  }
                                },
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isCollapsed: true,
                                ),
                              ),
                            ),
                            if (hasInput)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Icon(
                                  isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: cellSize * 0.28,
                                  color: isCorrect
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_isSolved)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: Colors.black54.withOpacity(0.55),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Puzzle Complete!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: TextSelection.collapsed(offset: upper.length),
      composing: TextRange.empty,
    );
  }
}
