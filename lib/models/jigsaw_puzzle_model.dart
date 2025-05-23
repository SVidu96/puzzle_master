import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart'; // For Size, Offset
import 'jigsaw_piece_model.dart';

class JigsawPuzzle {
  final String id;
  final ui.Image originalImage;
  List<JigsawPiece> pieces;
  final String difficulty; // e.g., "Easy", "Medium", "Hard"
  final Size boardSize; // Assembled puzzle dimensions
  final Size pieceGridSize; // e.g., 3x4 for 12 pieces

  JigsawPuzzle({
    required this.id,
    required this.originalImage,
    required this.pieces,
    required this.difficulty,
    required this.boardSize,
    required this.pieceGridSize,
  });

  /// Shuffles the `currentPosition` and `currentRotation` of pieces
  /// that are not yet assembled.
  void shufflePieces(Size availableArea) {
    final random = Random();
    final double boardWidth = availableArea.width;
    final double boardHeight = availableArea.height;

    for (var piece in pieces) {
      if (!piece.isAssembled) {
        // Random position within the available area
        // Ensure the piece is fully within the bounds
        final double randomX = random.nextDouble() * (boardWidth - piece.width);
        final double randomY = random.nextDouble() * (boardHeight - piece.height);
        piece.currentPosition = Offset(randomX, randomY);

        // Random rotation (0, 90, 180, 270 degrees)
        final int randomRotationSteps = random.nextInt(4); // 0, 1, 2, or 3
        piece.currentRotation = randomRotationSteps * (pi / 2);
      }
    }
  }

  /// Checks if all pieces are correctly placed and thus the puzzle is complete.
  bool isComplete() {
    if (pieces.isEmpty) return false; // Or true, depending on desired behavior for empty puzzle
    return pieces.every((piece) => piece.isAssembled || piece.isCorrectlyPlaced());
  }

  @override
  String toString() {
    return 'JigsawPuzzle{id: $id, difficulty: $difficulty, pieces: ${pieces.length}, isComplete: ${isComplete()}}';
  }
}
