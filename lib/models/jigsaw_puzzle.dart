import 'dart:math' show Random, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'jigsaw_piece.dart';

class JigsawPuzzle {
  final String id;
  final ui.Image originalImage;
  final List<JigsawPiece> pieces;
  final String difficulty;
  final Size boardSize;
  final Size gridSize;
  bool _isComplete = false;

  JigsawPuzzle({
    required this.id,
    required this.originalImage,
    required this.pieces,
    required this.difficulty,
    required this.boardSize,
    required this.gridSize,
  });

  bool get isComplete => _isComplete;

  static Future<JigsawPuzzle> create({
    required String id,
    required ui.Image image,
    required String difficulty,
    required Size boardSize,
  }) async {
    // Determine grid size based on difficulty
    Size gridSize;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        gridSize = const Size(3, 2); // 6 pieces
        break;
      case 'medium':
        gridSize = const Size(4, 3); // 12 pieces
        break;
      case 'hard':
        gridSize = const Size(5, 4); // 20 pieces
        break;
      default:
        gridSize = const Size(3, 2); // Default to easy
    }

    // Calculate piece dimensions
    final pieceWidth = boardSize.width / gridSize.width;
    final pieceHeight = boardSize.height / gridSize.height;

    // Create pieces
    final pieces = <JigsawPiece>[];
    for (int y = 0; y < gridSize.height; y++) {
      for (int x = 0; x < gridSize.width; x++) {
        final pieceId = '${x}_${y}';
        final correctPosition = Offset(x * pieceWidth, y * pieceHeight);
        
        // Extract piece image
        final pieceImage = await _extractPieceImage(
          image: image,
          row: y,
          col: x,
          pieceWidth: pieceWidth,
          pieceHeight: pieceHeight,
        );
        
        pieces.add(JigsawPiece(
          id: pieceId,
          image: pieceImage,
          correctPosition: correctPosition,
          width: pieceWidth,
          height: pieceHeight,
        ));
      }
    }

    return JigsawPuzzle(
      id: id,
      originalImage: image,
      pieces: pieces,
      difficulty: difficulty,
      boardSize: boardSize,
      gridSize: gridSize,
    );
  }

  void shufflePieces() {
    final random = Random();
    final boardRect = Rect.fromLTWH(0, 0, boardSize.width, boardSize.height);
    
    for (final piece in pieces) {
      // Generate random position within board bounds
      double x, y;
      do {
        x = random.nextDouble() * (boardSize.width - piece.width);
        y = random.nextDouble() * (boardSize.height - piece.height);
      } while (!boardRect.contains(Offset(x, y)));

      piece.position = Offset(x, y);
      piece.rotation = random.nextDouble() * 2 * pi;
      piece.isAssembled = false;
      piece.connectedPieces.clear();
    }
  }

  void checkCompletion() {
    _isComplete = pieces.every((piece) => piece.isAssembled);
  }

  void reset() {
    for (final piece in pieces) {
      piece.reset();
    }
    _isComplete = false;
  }

  static Future<ui.Image> _extractPieceImage({
    required ui.Image image,
    required int row,
    required int col,
    required double pieceWidth,
    required double pieceHeight,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final srcRect = Rect.fromLTWH(
      col * pieceWidth,
      row * pieceHeight,
      pieceWidth,
      pieceHeight,
    );
    final dstRect = Rect.fromLTWH(0, 0, pieceWidth, pieceHeight);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    final picture = recorder.endRecording();
    return picture.toImage(pieceWidth.round(), pieceHeight.round());
  }
} 