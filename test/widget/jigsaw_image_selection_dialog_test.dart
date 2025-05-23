import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_master/widgets/jigsaw_image_selection_dialog.dart';
import 'package:flutter/services.dart'; // Required for ByteData
import 'dart:typed_data'; // Required for Uint8List
import 'dart:ui' as ui; // Required for ui.Codec

// A basic implementation of an AssetBundle that allows us to mock image loading.
class TestAssetBundle extends CachingAssetBundle {
  // A map to hold our mock assets. Path -> ByteData
  final Map<String, ByteData> assets = {};

  // Helper to add a mock image asset
  Future<void> addMockImage(String path, int width, int height) async {
    final ByteData assetData = await createMockImageByteData(width, height);
    assets[path] = assetData;
  }

  @override
  Future<ByteData> load(String key) async {
    if (assets.containsKey(key)) {
      return assets[key]!;
    }
    // Fallback for other assets if needed, or throw an error
    // For this test, we only care about images in the dialog.
    // If it tries to load system fonts or other assets, let it pass through.
    if (key.startsWith('packages/cupertino_icons')) {
       // Attempt to load from rootBundle if it's a known package asset
      try {
        return await rootBundle.load(key);
      } catch (e) {
        print("Failed to load $key from rootBundle in test: $e");
        // Return a minimal valid ByteData if absolutely necessary to prevent crash,
        // though ideally tests should mock all essential assets.
        return ByteData(0); 
      }
    }
    print("TestAssetBundle: Asset not found for key: $key");
    // Return an empty ByteData or throw an exception if the asset is critical
    // For some image tests, an empty ByteData might lead to decode errors.
    // throw FlutterError('Asset not found: $key');
    return ByteData(0); // Minimal data to prevent some errors, actual image won't load
  }

  // Creates transparent image ByteData.
  static Future<ByteData> createMockImageByteData(int width, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = Colors.transparent);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!;
  }
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized

  // The list of images the dialog expects to find.
  final List<Map<String, String>> testJigsawImages = [
    {"path": "assets/images/jigsaw/landscape_mountain.jpg", "name": "Mountains"},
    {"path": "assets/images/jigsaw/landscape_beach.jpg", "name": "Beach"},
    {"path": "assets/images/jigsaw/animal_cat.jpg", "name": "Cat"},
    {"path": "assets/images/jigsaw/animal_bird.jpg", "name": "Bird"},
    {"path": "assets/images/jigsaw/abstract_colors.jpg", "name": "Abstract Colors"},
  ];

  // Create a TestAssetBundle instance and pre-populate it with mock images.
  final TestAssetBundle testAssetBundle = TestAssetBundle();

  setUpAll(() async {
    for (var imageMap in testJigsawImages) {
      await testAssetBundle.addMockImage(imageMap['path']!, 100, 100); // width/height don't matter much for existence checks
    }
  });

  Future<JigsawSelectionResult?> showTestDialog(WidgetTester tester) {
    return showDialog<JigsawSelectionResult>(
      context: tester.element(find.byType(MaterialApp)), // Use app context
      builder: (BuildContext context) {
        return const JigsawImageSelectionDialog();
      },
    );
  }

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('JigsawImageSelectionDialog displays images and allows selection', (WidgetTester tester) async {
    // Provide the mock asset bundle
    // DefaultAssetBundle.of(context) will now use our TestAssetBundle
    WidgetController.hitTestWarningShouldBeFatal = true;


    // Wrap the dialog call in a way that provides an Overlay and other necessary ancestors.
    // We can launch a dummy widget that then launches the dialog.
    JigsawSelectionResult? result;

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: testAssetBundle,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<JigsawSelectionResult>(
                    context: context,
                    builder: (dContext) => const JigsawImageSelectionDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      )
    );
    
    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle(); // Wait for dialog to appear and animations to settle

    // Test Dialog Display: Verify that the dialog shows up
    expect(find.byType(JigsawImageSelectionDialog), findsOneWidget);
    expect(find.text('Select Jigsaw Image'), findsOneWidget);

    // Test Image Options: Verify that the 5 image names/options are displayed
    for (var imageMap in testJigsawImages) {
      expect(find.text(imageMap['name']!), findsOneWidget, reason: "Could not find ${imageMap['name']}");
      // Also check for the Image widget itself by trying to find part of its path (less reliable) or by a common ancestor
      // A better way would be to add unique Keys to the Image widgets if possible.
      // For now, checking name is a good start.
    }
    
    // Test Difficulty Options (after selecting an image)
    // Select the first image ("Mountains")
    await tester.tap(find.text(testJigsawImages.first['name']!));
    await tester.pumpAndSettle(); // Wait for difficulty dialog to appear

    expect(find.text('Select Difficulty'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);

    // Test Selection: Simulate tapping a difficulty
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle(); // Wait for dialogs to close

    // Verify the dialog returns the expected JigsawSelectionResult
    expect(result, isNotNull);
    expect(result!.imagePath, equals(testJigsawImages.first['path']));
    expect(result!.difficulty, equals('Medium'));

    // Verify the dialog is closed
    expect(find.byType(JigsawImageSelectionDialog), findsNothing);
  });

   testWidgets('JigsawImageSelectionDialog cancel image selection', (WidgetTester tester) async {
    JigsawSelectionResult? result;
     await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: testAssetBundle,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<JigsawSelectionResult>(
                    context: context,
                    builder: (dContext) => const JigsawImageSelectionDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      )
    );
    
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(JigsawImageSelectionDialog), findsOneWidget);
    
    // Tap cancel button
    expect(find.text('Cancel'), findsOneWidget); // This cancel is for image selection part
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byType(JigsawImageSelectionDialog), findsNothing);
  });

  testWidgets('JigsawImageSelectionDialog cancel difficulty selection', (WidgetTester tester) async {
    JigsawSelectionResult? result;
     await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: testAssetBundle,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<JigsawSelectionResult>(
                    context: context,
                    builder: (dContext) => const JigsawImageSelectionDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      )
    );
    
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
    
    // Select an image to proceed to difficulty selection
    await tester.tap(find.text(testJigsawImages.first['name']!));
    await tester.pumpAndSettle();

    expect(find.text('Select Difficulty'), findsOneWidget);
    
    // Tap cancel button in difficulty dialog
    // The "Cancel" button in the difficulty dialog's actions
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull); // Result should be null as difficulty selection was cancelled
    expect(find.byType(JigsawImageSelectionDialog), findsNothing); // Main dialog should also close
  });
}
