
import 'package:flutter/material.dart';
import 'package:senior_games/models/crossword_model.dart';

class CrosswordGrid extends StatelessWidget {
  final CrosswordModel crossword;

  const CrosswordGrid({super.key, required this.crossword});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowCount = crossword.grid.length;
        final colCount = rowCount > 0 ? crossword.grid[0].length : 0;
        final cellSize = constraints.maxWidth / colCount;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colCount,
          ),
          itemBuilder: (context, index) {
            final row = index ~/ colCount;
            final col = index % colCount;
            if (row >= rowCount || col >= colCount) {
              return const SizedBox.shrink();
            }
            final cell = crossword.grid[row][col];

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54),
                color: cell.isEmpty ? Colors.black26 : Colors.white,
              ),
              child: cell.isEmpty
                  ? const SizedBox.shrink()
                  : Stack(
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: cellSize * 0.5,
                              color: cell.isCorrect ? Colors.green : Colors.black,
                            ),
                            maxLength: 1,
                            onChanged: (value) {
                              cell.currentLetter = value;
                              cell.checkLetter();
                              crossword.checkSolution();
                            },
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
          itemCount: rowCount * colCount,
        );
      },
    );
  }
}
