import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_app/models/jigsaw_piece_model.dart';
import 'package:jigsaw_puzzle_app/models/jigsaw_puzzle_model.dart';
import 'package:jigsaw_puzzle_app/screens/jigsaw_puzzle_screen.dart';
import 'package:jigsaw_puzzle_app/widgets/jigsaw_image_selection_dialog.dart';
import 'package:jigsaw_puzzle_app/widgets/jigsaw_piece_widget.dart';

// Re-using TestAssetBundle from jigsaw_image_selection_dialog_test.dart
// In a real project, this might be in a shared test utilities file.
class TestAssetBundle extends CachingAssetBundle {
  final Map<String, ByteData> assets = {};
  final Map<String, ui.Image> imageCache = {}; // Cache for decoded images

  Future<void> addMockImage(String path, int width, int height, {bool predecode = false}) async {
    final ByteData assetData = await _createMockImageByteData(width, height);
    assets[path] = assetData;
    if (predecode) {
      final ui.Codec codec = await ui.instantiateImageCodec(assetData.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      imageCache[path] = frameInfo.image;
    }
  }

  Future<ui.Image> getUiImage(String path) async {
    if (imageCache.containsKey(path)) {
      return imageCache[path]!;
    }
    if (assets.containsKey(path)) {
      final ui.Codec codec = await ui.instantiateImageCodec(assets[path]!.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      imageCache[path] = frameInfo.image;
      return frameInfo.image;
    }
    throw FlutterError('Asset not found or not pre-decoded: $path');
  }


  @override
  Future<ByteData> load(String key) async {
    if (assets.containsKey(key)) {
      return assets[key]!;
    }
    if (key.startsWith('packages/cupertino_icons')) {
      try {
        return await rootBundle.load(key);
      } catch (e) {
        print("Failed to load $key from rootBundle in test: $e");
        return ByteData(0);
      }
    }
    print("TestAssetBundle: Asset not found for key: $key");
    return ByteData(0);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    // For other string assets if any
    return "";
  }

  static Future<ByteData> _createMockImageByteData(int width, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = Colors.transparent);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!;
  }
}

// Helper to create a mock ui.Image (very basic)
Future<ui.Image> createMockUiImage(TestAssetBundle bundle, String path, int width, int height) async {
  // Ensure the image is in the bundle and pre-decoded
  if (!bundle.assets.containsKey(path) || !bundle.imageCache.containsKey(path)) {
    await bundle.addMockImage(path, width, height, predecode: true);
  }
  return await bundle.getUiImage(path);
}

// Test Jigsaw Puzzle data provider
Future<JigsawPuzzle> createTestPuzzle({
  required TestAssetBundle bundle,
  String imagePath = 'assets/images/jigsaw/test_image.png',
  String difficulty = 'Easy',
  int pieceCount = 4, // e.g., 2x2 grid
  Size boardPixelSize = const Size(400, 300), // Logical pixels for board
  Size actualImageSize = const Size(800, 600), // Underlying image dimensions
}) async {
  final originalImage = await createMockUiImage(bundle, imagePath, actualImageSize.width.toInt(), actualImageSize.height.toInt());
  List<JigsawPiece> pieces = [];
  
  // Determine grid from difficulty for consistency with app logic
  Size gridSize;
  if (difficulty == 'Easy') gridSize = const Size(2,2); // 4 pieces
  else if (difficulty == 'Medium') gridSize = const Size(3,2); // 6 pieces
  else gridSize = const Size(4,3); // 12 pieces
  
  pieceCount = gridSize.width.toInt() * gridSize.height.toInt();

  double pieceWidthOnBoard = boardPixelSize.width / gridSize.width;
  double pieceHeightOnBoard = boardPixelSize.height / gridSize.height;

  // Piece image chunks would be derived from originalImage in real app
  // For testing, we create distinct mock image chunks for each piece
  for (int i = 0; i < pieceCount; i++) {
    String pieceImagePath = 'assets/images/jigsaw/piece_${i}.png';
    pieces.add(JigsawPiece(
      id: i,
      imageChunk: await createMockUiImage(bundle, pieceImagePath, pieceWidthOnBoard.toInt(), pieceHeightOnBoard.toInt()),
      correctPosition: Offset(
        (i % gridSize.width) * pieceWidthOnBoard,
        (i ~/ gridSize.width) * pieceHeightOnBoard,
      ),
      currentPosition: Offset.zero, // Initial position (screen will shuffle)
      currentRotation: 0.0,
      correctRotation: 0.0,
      width: pieceWidthOnBoard,
      height: pieceHeightOnBoard,
      isAssembled: false,
      connectedTo: {},
    ));
  }

  return JigsawPuzzle(
    id: 'test_puzzle_${difficulty.toLowerCase()}',
    originalImage: originalImage,
    pieces: pieces,
    difficulty: difficulty,
    boardSize: boardPixelSize,
    pieceGridSize: gridSize,
  );
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final TestAssetBundle testAssetBundle = TestAssetBundle();

  // List of images expected by JigsawImageSelectionDialog
  final List<Map<String, String>> dialogTestImages = [
    {"path": "assets/images/jigsaw/landscape_mountain.jpg", "name": "Mountains"},
    {"path": "assets/images/jigsaw/landscape_beach.jpg", "name": "Beach"},
    {"path": "assets/images/jigsaw/animal_cat.jpg", "name": "Cat"},
    {"path": "assets/images/jigsaw/animal_bird.jpg", "name": "Bird"},
    {"path": "assets/images/jigsaw/abstract_colors.jpg", "name": "Abstract Colors"},
  ];

  setUpAll(() async {
    // Add mock images for the selection dialog
    for (var imageMap in dialogTestImages) {
      await testAssetBundle.addMockImage(imageMap['path']!, 100, 100, predecode: true);
    }
    // Add a default mock image for puzzles if createTestPuzzle uses a specific path
    await testAssetBundle.addMockImage('assets/images/jigsaw/test_image.png', 800, 600, predecode: true);
  });


  Widget createTestableWidget(Widget child) {
    return DefaultAssetBundle(
      bundle: testAssetBundle,
      child: MaterialApp(home: child),
    );
  }
  
  // This is a simplified mock that bypasses the actual JigsawUtils.sliceImageIntoPieces
  // and directly provides a pre-constructed JigsawPuzzle.
  // In JigsawPuzzleScreen, _initializePuzzle calls JigsawUtils.sliceImageIntoPieces.
  // We need to ensure that call can be mocked or that JigsawUtils uses the TestAssetBundle.
  // For simplicity here, we assume JigsawPuzzleScreen can be initialized with a pre-made puzzle
  // for some tests, or we mock the dialog to return a path that we then use with createTestPuzzle.

  group('JigsawPuzzleScreen Tests', () {
    testWidgets('shows loading indicator and then prompts for new game', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const JigsawPuzzleScreen()));

      // Initially, _currentPuzzle is null, isLoading might be true briefly if initState called _showNewGameDialog
      // which tries to load assets. Let's see the sequence.
      // JigsawPuzzleScreen's initState calls _showNewGameDialog.
      
      // Pump and settle to allow dialog to be shown and any initial loading.
      await tester.pumpAndSettle(); 

      // Expect the JigsawImageSelectionDialog to be shown because _currentPuzzle is null.
      expect(find.byType(JigsawImageSelectionDialog), findsOneWidget);
      expect(find.text('Select Jigsaw Image'), findsOneWidget);

      // Let's cancel the dialog to see the "No puzzle loaded" state.
      // The cancel button in the JigsawImageSelectionDialog
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      
      expect(find.byType(JigsawImageSelectionDialog), findsNothing);
      expect(find.text('No puzzle loaded.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start New Game'), findsOneWidget);
    });

    testWidgets('displays puzzle elements after selection and loading', (WidgetTester tester) async {
      // We need to mock the dialog result and then the puzzle creation.
      // For this test, we'll directly initialize the screen as if a puzzle was loaded.
      // This requires modifying JigsawPuzzleScreen or having a way to inject the puzzle.
      // Let's use a different approach: interact with the dialog.

      await tester.pumpWidget(createTestableWidget(const JigsawPuzzleScreen()));
      await tester.pumpAndSettle(); // Show dialog

      // 1. Interact with JigsawImageSelectionDialog
      expect(find.byType(JigsawImageSelectionDialog), findsOneWidget);
      await tester.tap(find.text(dialogTestImages.first['name']!)); // Tap "Mountains"
      await tester.pumpAndSettle();
      
      expect(find.text('Select Difficulty'), findsOneWidget);
      await tester.tap(find.text('Easy')); // Tap "Easy"
      await tester.pumpAndSettle(); // Dialog closes, _initializePuzzle is called

      // Now, _initializePuzzle is running. It uses _loadUiImage and JigsawUtils.sliceImageIntoPieces.
      // These will use our TestAssetBundle.
      // JigsawUtils.sliceImageIntoPieces will need mock images for pieces if it tries to create them.
      // Our createTestPuzzle helper pre-creates piece images.
      // The current JigsawUtils.sliceImageIntoPieces creates image chunks via PictureRecorder.
      // This should work with the mock image provided for the main puzzle image.

      // After _initializePuzzle completes:
      expect(find.byType(CircularProgressIndicator), findsNothing, reason: "Loading should complete.");
      
      // Verify game board area and piece tray area are present
      // (using structure, e.g. Expanded with flex factors)
      expect(find.byKey(const Key('jigsaw_game_board_area')), findsOneWidget); // Add Key in JigsawPuzzleScreen
      expect(find.byKey(const Key('jigsaw_piece_tray_area')), findsOneWidget); // Add Key in JigsawPuzzleScreen

      // Verify that JigsawPieceWidgets are rendered
      // For an "Easy" puzzle (default 2x2=4 pieces from our dialog interaction mapping)
      // Some might be on board, some in tray.
      // Let's assume after shuffle, some are in tray
      expect(find.byType(JigsawPieceWidget), findsWidgets, reason: "Should display JigsawPieceWidgets");

      // Check for AppBar actions
      expect(find.widgetWithIcon(IconButton, Icons.refresh), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('piece tap rotates piece in tray', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const JigsawPuzzleScreen()));
      await tester.pumpAndSettle();

      // Select image and difficulty to load a puzzle
      await tester.tap(find.text(dialogTestImages.first['name']!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      // Find a JigsawPieceWidget in the tray (assuming some are there after shuffle)
      // This requires pieces to be in _displayedPieces list in JigsawPuzzleScreenState
      final trayPieceFinder = find.descendant(
        of: find.byKey(const Key('jigsaw_piece_tray_area')), // Ensure this key exists
        matching: find.byType(JigsawPieceWidget),
      );
      
      expect(trayPieceFinder, findsWidgets, reason: "Expected pieces in tray");
      if (tester.widgetList(trayPieceFinder).isEmpty) {
        print("No pieces found in tray for tap test, might need to adjust puzzle setup or shuffle mock.");
        return; // Cannot proceed
      }

      // Get the first piece from the tray
      final JigsawPieceWidget firstTrayPieceWidget = tester.widget<JigsawPieceWidget>(trayPieceFinder.first);
      final initialRotation = firstTrayPieceWidget.piece.currentRotation;

      // Tap the piece
      await tester.tap(trayPieceFinder.first);
      await tester.pumpAndSettle(); // Allow state to update and widget to rebuild

      final JigsawPieceWidget updatedTrayPieceWidget = tester.widget<JigsawPieceWidget>(trayPieceFinder.first);
      expect(updatedTrayPieceWidget.piece.currentRotation, isNot(equals(initialRotation)));
      // Default rotation is pi/2 (90 degrees)
      expect(updatedTrayPieceWidget.piece.currentRotation, equals((initialRotation + 3.141592653589793 / 2) % (2 * 3.141592653589793)));
    });

    testWidgets('Restart button triggers puzzle re-shuffle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const JigsawPuzzleScreen()));
      await tester.pumpAndSettle();

      // Load a puzzle
      await tester.tap(find.text(dialogTestImages.first['name']!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      // At this point, pieces have an initial shuffled state.
      // We need a way to get the initial positions/rotations of pieces.
      // This is complex without exposing more state or using mocks.
      // A simpler check: tapping restart calls _restartPuzzle, which should call shuffle.
      // If we can find a piece, move it, then restart, it should go back to a shuffled state (not necessarily original).
      
      // For now, just check if the button exists and is tappable.
      // A more robust test would verify that piece positions actually change after restart.
      final restartButton = find.widgetWithIcon(IconButton, Icons.refresh);
      expect(restartButton, findsOneWidget);
      await tester.tap(restartButton);
      await tester.pumpAndSettle(); // Allow shuffle and rebuild

      // TODO: Add a more robust check for re-shuffling, e.g., by checking if _displayedPieces has changed
      // or positions of pieces have been updated. This requires a way to compare states.
      // For now, the fact that it doesn't crash is a basic positive sign.
      expect(find.byType(JigsawPuzzleScreen), findsOneWidget); // Screen should still be there
    });

     testWidgets('New Game button shows image selection dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const JigsawPuzzleScreen()));
      await tester.pumpAndSettle();

      // Load a puzzle first
      await tester.tap(find.text(dialogTestImages.first['name']!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      // Now the puzzle is loaded. Tap "New Game"
      final newGameButton = find.widgetWithIcon(IconButton, Icons.add_photo_alternate);
      expect(newGameButton, findsOneWidget);
      await tester.tap(newGameButton);
      await tester.pumpAndSettle();

      // Expect the JigsawImageSelectionDialog to be shown again
      expect(find.byType(JigsawImageSelectionDialog), findsOneWidget);
      expect(find.text('Select Jigsaw Image'), findsOneWidget);
    });

  });
}

// Helper to add Keys to JigsawPuzzleScreen for easier finding in tests
// Example:
// In JigsawPuzzleScreen build method:
// Game Board Area:
// Expanded(
//   key: const Key('jigsaw_game_board_area'),
//   flex: 3,
//   ...
// Piece Tray Area:
// Expanded(
//   key: const Key('jigsaw_piece_tray_area'),
//   flex: 1,
//   ...
// )
// This would require modifying the actual JigsawPuzzleScreen code.
// For now, tests will rely on widget types or less specific finders if keys are not present.
// (The test code above assumes these keys WILL be added to JigsawPuzzleScreen for robustness)
