import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';
import '../widgets/jigsaw_difficulty_dialog.dart';
import 'package:flutter/services.dart' show rootBundle;

class JigsawPuzzleScreen extends StatefulWidget {
  const JigsawPuzzleScreen({super.key});

  @override
  State<JigsawPuzzleScreen> createState() => _JigsawPuzzleScreenState();
}

class _JigsawPuzzleScreenState extends State<JigsawPuzzleScreen> {
  List<PuzzlePiece> _puzzlePieces = [];
  String _currentDifficulty = 'easy';
  bool _dialogShown = false;
  bool _showCongratulations = false;
  Image? _selectedImage;
  ui.Image? _rawImage;
  final List<String> _availableImages = [
    'assets/images/puzzle1.jpg',
    'assets/images/puzzle2.jpg',
    'assets/images/puzzle3.jpg',
    'assets/images/puzzle4.jpg',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      Future.microtask(() => _showImageSelectionDialog());
    }
  }

  Future<void> _showImageSelectionDialog() async {
    final selectedImagePath = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade100,
                Colors.amber.shade100,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose an Image',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _availableImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, _availableImages[index]),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          _availableImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (selectedImagePath != null) {
      setState(() {
        _selectedImage = Image.asset(selectedImagePath);
      });
      // Load the raw image
      final rawImage = await loadUiImage(selectedImagePath);
      setState(() {
        _rawImage = rawImage;
      });
      // Now initialize the puzzle
      _showDifficultyDialog();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _showDifficultyDialog() async {
    final difficulty = await showDialog<String>(
      context: context,
      builder: (context) => const JigsawDifficultyDialog(),
    );

    if (!mounted) return;

    if (difficulty != null) {
      setState(() {
        _currentDifficulty = difficulty;
        _initializePuzzle();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _initializePuzzle() {
    if (_selectedImage == null || _rawImage == null) return;

    final gridSize = _getGridSize();
    final random = Random();
    _puzzlePieces = List.generate(
      gridSize * gridSize,
      (index) {
        final row = index ~/ gridSize;
        final col = index % gridSize;
        final imgWidth = _rawImage!.width;
        final imgHeight = _rawImage!.height;
        final pieceWidth = imgWidth / gridSize;
        final pieceHeight = imgHeight / gridSize;

        // Calculate the source rectangle for this piece
        final sourceRect = Rect.fromLTWH(
          col * pieceWidth,
          row * pieceHeight,
          pieceWidth,
          pieceHeight,
        );

        return PuzzlePiece(
          id: index,
          correctPosition: index,
          image: _selectedImage!,
          sourceRect: sourceRect,
          targetRect: sourceRect, // Target rect is the same as source for now
          currentPosition: index,
        );
      },
    )..shuffle(random);
  }

  int _getGridSize() {
    switch (_currentDifficulty) {
      case 'easy':
        return 3;
      case 'medium':
        return 4;
      case 'hard':
        return 5;
      default:
        return 3;
    }
  }

  void _checkWinCondition() {
    final allPiecesPlaced = _puzzlePieces.asMap().entries.every(
      (entry) => entry.value.correctPosition == entry.key,
    );
    if (allPiecesPlaced) {
      setState(() {
        _showCongratulations = true;
      });
    }
  }

  void _startNewGame() {
    setState(() {
      _showCongratulations = false;
      _dialogShown = false;
    });
    Future.microtask(() => _showImageSelectionDialog());
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedImage == null || _puzzlePieces.isEmpty || _rawImage == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jigsaw Puzzle'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.grey[100]!,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Difficulty: ${_currentDifficulty[0].toUpperCase()}${_currentDifficulty.substring(1)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getGridSize(),
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _puzzlePieces.length,
                      itemBuilder: (context, index) {
                        final piece = _puzzlePieces[index];
                        return DragTarget<int>(
                          onWillAccept: (data) => true,
                          onAccept: (data) {
                            setState(() {
                              final draggedIndex = _puzzlePieces.indexWhere((p) => p.id == data);
                              final targetIndex = index;
                              // Swap the pieces in the list
                              final temp = _puzzlePieces[draggedIndex];
                              _puzzlePieces[draggedIndex] = _puzzlePieces[targetIndex];
                              _puzzlePieces[targetIndex] = temp;
                              _checkWinCondition();
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: piece.isPlaced ? Colors.green : Colors.orange,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Draggable<int>(
                                data: piece.id,
                                feedback: Material(
                                  elevation: 4,
                                  child: SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: PuzzlePieceWidget(
                                      image: _rawImage!,
                                      srcRect: piece.sourceRect,
                                      size: 100,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Container(
                                  color: Colors.grey[200],
                                ),
                                child: piece.isPlaced
                                    ? PuzzlePieceWidget(
                                        image: _rawImage!,
                                        srcRect: piece.sourceRect,
                                        size: 100,
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: PuzzlePieceWidget(
                                          image: _rawImage!,
                                          srcRect: piece.sourceRect,
                                          size: 100,
                                        ),
                                      ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCongratulations)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.shade100,
                          Colors.amber.shade100,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration,
                          color: Colors.orange,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Congratulations!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You completed the ${_currentDifficulty} puzzle!',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _startNewGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start New Game',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PuzzlePieceWidget extends StatelessWidget {
  final ui.Image image;
  final Rect srcRect; // in pixel coordinates
  final double size;  // size of the puzzle piece widget

  const PuzzlePieceWidget({
    required this.image,
    required this.srcRect,
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PuzzlePiecePainter(image, srcRect),
    );
  }
}

class _PuzzlePiecePainter extends CustomPainter {
  final ui.Image image;
  final Rect srcRect;

  _PuzzlePiecePainter(this.image, this.srcRect);

  @override
  void paint(Canvas canvas, Size size) {
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<ui.Image> loadUiImage(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
} 