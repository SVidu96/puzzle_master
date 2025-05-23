import 'package:flutter/material.dart';
import 'package:puzzle_master/models/jigsaw_piece_model.dart';
import 'package:puzzle_master/widgets/jigsaw_piece_painter.dart';

class JigsawPieceWidget extends StatelessWidget {
  final JigsawPiece piece;
  final bool isSelected; // To highlight if the piece is selected or being dragged

  const JigsawPieceWidget({
    super.key,
    required this.piece,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // The CustomPaint widget will take the size of the piece itself.
    // The JigsawPiecePainter will then draw the imageChunk centered and rotated
    // within these bounds.
    return SizedBox(
      width: piece.width,
      height: piece.height,
      child: CustomPaint(
        painter: JigsawPiecePainter(
          imageChunk: piece.imageChunk,
          rotationAngle: piece.currentRotation,
          borderColor: Colors.black.withAlpha((255 * 0.5).round()),
          borderWidth: 1.0,
          isSelected: isSelected,
        ),
      ),
    );
  }
}
