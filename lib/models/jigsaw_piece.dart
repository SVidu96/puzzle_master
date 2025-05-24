import 'dart:ui' as ui;
import 'dart:math' show pi;
import 'package:flutter/material.dart';

class JigsawPiece {
  final String id;
  final ui.Image image;
  final Offset correctPosition;
  final double width;
  final double height;
  final Set<String> connectedPieces;
  bool isAssembled;
  double rotation;
  Offset position;

  JigsawPiece({
    required this.id,
    required this.image,
    required this.correctPosition,
    required this.width,
    required this.height,
    this.isAssembled = false,
    this.rotation = 0,
    Offset? position,
  }) : 
    connectedPieces = {},
    position = position ?? correctPosition;

  bool isCorrectlyPlaced() {
    final distance = (position - correctPosition).distance;
    return distance < 20.0 && rotation == 0;
  }

  void rotate() {
    rotation = (rotation + pi / 2) % (2 * pi);
  }

  void reset() {
    position = correctPosition;
    rotation = 0;
    isAssembled = false;
    connectedPieces.clear();
  }

  JigsawPiece copy() {
    return JigsawPiece(
      id: id,
      image: image,
      correctPosition: correctPosition,
      width: width,
      height: height,
      isAssembled: isAssembled,
      rotation: rotation,
      position: position,
    );
  }
} 