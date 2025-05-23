import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart'; // For Size, Offset
import 'package:jigsaw_puzzle_app/models/jigsaw_piece_model.dart';
import 'package:jigsaw_puzzle_app/models/jigsaw_puzzle_model.dart';

class JigsawUtils {
  /// Slices the given [image] into a grid of [gridSize] and returns a [JigsawPuzzle].
  ///
  /// The [difficulty] string is stored in the puzzle model.
  /// [puzzleId] is a unique identifier for this puzzle instance.
  /// [boardSize] represents the final assembled dimensions on the UI.
  static Future<JigsawPuzzle> sliceImageIntoPieces({
    required String puzzleId,
    required ui.Image image,
    required Size gridSize, // e.g., Size(4, 3) for a 4x3 grid
    required String difficulty,
    required Size boardSize, // The target display size of the assembled puzzle
  }) async {
    final List<JigsawPiece> pieces = [];
    final int numCols = gridSize.width.toInt();
    final int numRows = gridSize.height.toInt();

    // Calculate the size of each piece based on the original image dimensions
    final double pieceWidth = image.width / numCols;
    final double pieceHeight = image.height / numRows;

    // Calculate the scale factor between the original image and the board size
    final double scaleX = boardSize.width / image.width;
    final double scaleY = boardSize.height / image.height;
    // For uniform scaling, one might choose min(scaleX, scaleY) or max(scaleX, scaleY)
    // or handle aspect ratio differences in the UI. Here we assume boardSize
    // respects the original image's aspect ratio for simplicity in piece scaling.
    // If not, pieces might appear stretched or compressed on the board.
    // Let's assume the boardSize is determined such that aspect ratio is maintained,
    // so piece dimensions on board are scaled versions of original piece dimensions.
    final double scaledPieceWidth = pieceWidth * scaleX;
    final double scaledPieceHeight = pieceHeight * scaleY;


    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numCols; col++) {
        final int pieceId = row * numCols + col;

        // Crop the image chunk
        // This requires converting ui.Image to something that can be drawn and clipped,
        // then back to ui.Image.
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);

        // Create a rect for the portion of the original image to be used for this piece
        final Rect srcRect = Rect.fromLTWH(
          col * pieceWidth,
          row * pieceHeight,
          pieceWidth,
          pieceHeight,
        );

        // Destination rect for drawing the chunk (will be at 0,0 in its own image)
        final Rect dstRect = Rect.fromLTWH(0, 0, pieceWidth, pieceHeight);

        // Clip the canvas to the piece's dimensions before drawing.
        // Although simple rectangular clip is done here, for actual jigsaw shapes,
        // a custom path would be used with canvas.clipPath().
        // canvas.clipRect(dstRect); // Not needed if drawImageRect handles it

        canvas.drawImageRect(image, srcRect, dstRect, Paint());

        // Finish recording and get the image chunk
        final ui.Picture picture = recorder.endRecording();
        // Dimensions here should match dstRect width/height for the cropped image
        final ui.Image imageChunk = await picture.toImage(
          pieceWidth.round(), // Use original piece dimensions for the image data
          pieceHeight.round(),
        );

        // Correct position is scaled according to the boardSize
        final Offset correctPosition = Offset(
          col * scaledPieceWidth,
          row * scaledPieceHeight,
        );

        pieces.add(JigsawPiece(
          id: pieceId,
          imageChunk: imageChunk,
          correctPosition: correctPosition,
          currentPosition: Offset.zero, // Will be shuffled later
          currentRotation: 0.0,
          correctRotation: 0.0, // Assuming pieces are pre-oriented
          width: scaledPieceWidth, // Piece dimensions on the board
          height: scaledPieceHeight,
          isAssembled: false,
        ));
      }
    }

    return JigsawPuzzle(
      id: puzzleId,
      originalImage: image,
      pieces: pieces,
      difficulty: difficulty,
      boardSize: boardSize,
      pieceGridSize: gridSize,
    );
  }

  /// Checks if two pieces, [piece1] and [piece2], should snap together.
  ///
  /// Considers their proximity based on `correctPosition` and `currentPosition`,
  /// and if their `currentRotation` matches their `correctRotation`.
  /// [snapTolerance] defines how close pieces need to be to snap.
  ///
  /// This is a simplified version for rectangular pieces. For pieces with
  /// complex interlocking shapes, edge-matching algorithms would be needed.
  static bool shouldSnap({
    required JigsawPiece piece1,
    required JigsawPiece piece2,
    required double snapTolerance,
    required Size pieceGridSize, // To determine adjacency
    required Size boardSize,       // To calculate scaled piece dimensions
  }) {
    if (piece1.isAssembled && piece2.isAssembled && piece1.connectedTo.contains(piece2.id)) {
      // Already connected and assembled as part of the same group
      return false;
    }

    // Check rotation: for this basic version, pieces should be in their correct orientation
    // or at least oriented consistently if group rotation is allowed.
    // For simplicity, let's assume they must match their correctRotation.
    // A more advanced check might see if their relative rotation is correct.
    if ((piece1.currentRotation - piece1.correctRotation).abs() > 0.01 ||
        (piece2.currentRotation - piece2.correctRotation).abs() > 0.01) {
      return false;
    }

    // Determine if pieces are adjacent in the original grid
    final int numCols = pieceGridSize.width.toInt();
    final int piece1Row = piece1.id ~/ numCols;
    final int piece1Col = piece1.id % numCols;
    final int piece2Row = piece2.id ~/ numCols;
    final int piece2Col = piece2.id % numCols;

    final bool areAdjacent = (piece1Row == piece2Row && (piece1Col - piece2Col).abs() == 1) ||
                             (piece1Col == piece2Col && (piece1Row - piece2Row).abs() == 1);

    if (!areAdjacent) {
      return false;
    }

    // Calculate the expected offset between the correct positions of piece1 and piece2
    final Offset expectedOffsetCorrect = piece2.correctPosition - piece1.correctPosition;

    // Calculate the actual offset between the current positions of piece1 and piece2
    final Offset actualOffsetCurrent = piece2.currentPosition - piece1.currentPosition;

    // Check if the current relative positioning matches the correct relative positioning
    final double dx = actualOffsetCurrent.dx - expectedOffsetCorrect.dx;
    final double dy = actualOffsetCurrent.dy - expectedOffsetCorrect.dy;

    return dx.abs() < snapTolerance && dy.abs() < snapTolerance;
  }

  /// Snaps piece2 to piece1.
  /// Updates piece2's currentPosition and currentRotation to align with piece1,
  /// based on their correct relative placement.
  /// Marks both pieces as assembled and updates their connectedTo sets.
  static void snapPieces(JigsawPiece piece1, JigsawPiece piece2) {
    // The core idea is that if piece1 is considered the anchor (or already assembled),
    // piece2's currentPosition should be adjusted based on piece1's currentPosition
    // and their known correct relative layout.

    // Calculate the vector from piece1's correct top-left to piece2's correct top-left
    final Offset correctRelativeOffset = piece2.correctPosition - piece1.correctPosition;

    // Set piece2's new currentPosition based on piece1's currentPosition
    piece2.currentPosition = piece1.currentPosition + correctRelativeOffset;

    // Align rotation (assuming they should match their correctRotations,
    // or if piece1 is correctly rotated, piece2 should also be)
    piece2.currentRotation = piece2.correctRotation; // Or piece1.currentRotation if group rotation is considered

    // Update assembly and connection status
    piece1.isAssembled = true;
    piece2.isAssembled = true;
    piece1.connectedTo.add(piece2.id);
    piece2.connectedTo.add(piece1.id);

    // If piece1 is part of a larger group, piece2 (and its connections) should join that group.
    // This part can get complex with transitive connections and needs a robust way
    // to merge groups of assembled pieces. For now, we handle direct connections.
    // A more advanced system might involve a Disjoint Set Union (DSU) data structure
    // to manage groups of connected pieces.

    print("Snapped piece ${piece2.id} to ${piece1.id}");
  }

  /// Rotates a piece by 90 degrees clockwise.
  static void rotatePiece(JigsawPiece piece) {
    // Cycle through 0, pi/2, pi, 3*pi/2
    piece.currentRotation = (piece.currentRotation + pi / 2) % (2 * pi);
  }
}
