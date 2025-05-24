import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/jigsaw_piece.dart';

class JigsawPieceWidget extends StatelessWidget {
  final JigsawPiece piece;
  final bool isSelected;

  const JigsawPieceWidget({
    super.key,
    required this.piece,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: piece.rotation,
      child: Container(
        width: piece.width,
        height: piece.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: ClipRect(
          child: RawImage(
            image: piece.image,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
