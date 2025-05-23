import 'dart:ui' as ui;
import 'package:flutter/material.dart'; // For Offset, if not using ui.Offset

class JigsawPiece {
  final int id;
  final ui.Image imageChunk;
  final Offset correctPosition;
  Offset currentPosition;
  double currentRotation;
  final double correctRotation; // Likely 0.0 for pre-rotated chunks
  final double width;
  final double height;
  bool isAssembled;
  Set<int> connectedTo;

  JigsawPiece({
    required this.id,
    required this.imageChunk,
    required this.correctPosition,
    required this.currentPosition,
    this.currentRotation = 0.0,
    this.correctRotation = 0.0,
    required this.width,
    required this.height,
    this.isAssembled = false,
    Set<int>? connectedTo,
  }) : this.connectedTo = connectedTo ?? {};

  /// Checks if the piece is currently at its correct position and rotation.
  bool isCorrectlyPlaced() {
    // Define a small tolerance for position checking
    const double positionTolerance = 2.0; // pixels
    // Define a small tolerance for rotation checking (in radians)
    const double rotationTolerance = 0.01; // radians

    final bool positionCorrect =
        (currentPosition.dx - correctPosition.dx).abs() < positionTolerance &&
        (currentPosition.dy - correctPosition.dy).abs() < positionTolerance;

    // Normalize rotations to be within 0 to 2*pi for comparison
    final normalizedCurrentRotation = currentRotation % (2 * 3.1415926535);
    final normalizedCorrectRotation = correctRotation % (2 * 3.1415926535);

    final bool rotationCorrect =
        (normalizedCurrentRotation - normalizedCorrectRotation).abs() < rotationTolerance;

    return positionCorrect && rotationCorrect;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JigsawPiece && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode; // Assuming this.id was here before based on common patterns

  @override
  String toString() {
    return 'JigsawPiece{id: $id, correctPosition: $correctPosition, currentPosition: $currentPosition, currentRotation: $currentRotation, isAssembled: $isAssembled}';
  }
}
