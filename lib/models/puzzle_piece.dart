import 'package:flutter/material.dart';

class PuzzlePiece {
  final int id;
  final int correctPosition;
  int currentPosition;
  final Image image;
  final Rect sourceRect;
  final Rect targetRect;
  bool isPlaced;

  PuzzlePiece({
    required this.id,
    required this.correctPosition,
    required this.image,
    required this.sourceRect,
    required this.targetRect,
    required this.currentPosition,
    this.isPlaced = false,
  });

  PuzzlePiece copyWith({
    int? currentPosition,
    bool? isPlaced,
  }) {
    return PuzzlePiece(
      id: id,
      correctPosition: correctPosition,
      image: image,
      sourceRect: sourceRect,
      targetRect: targetRect,
      currentPosition: currentPosition ?? this.currentPosition,
      isPlaced: isPlaced ?? this.isPlaced,
    );
  }

  Widget buildPiece() {
    return ClipRect(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image(
          image: image.image,
          fit: BoxFit.cover,
          alignment: Alignment(
            (sourceRect.left * 2.0) - 1.0,
            (sourceRect.top * 2.0) - 1.0,
          ),
        ),
      ),
    );
  }

  double get scaleFactor {
    // Calculate the scale needed to show the correct portion
    // We need to scale up enough to show just this piece's portion
    return 1.0 / sourceRect.width;
  }

  int _getGridSize() {
    // This is a helper method to determine the grid size based on difficulty
    // You can adjust these values based on your difficulty levels
    return 3; // Default to 3x3 grid
  }
} 