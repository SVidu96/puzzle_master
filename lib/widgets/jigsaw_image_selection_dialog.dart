import 'package:flutter/material.dart';

// Represents the data returned by the dialog
class JigsawSelectionResult {
  final String imagePath;
  final String difficulty; // "Easy", "Medium", "Hard"

  JigsawSelectionResult({required this.imagePath, required this.difficulty});
}

class JigsawImageSelectionDialog extends StatefulWidget {
  const JigsawImageSelectionDialog({super.key});

  @override
  State<JigsawImageSelectionDialog> createState() =>
      _JigsawImageSelectionDialogState();
}

class _JigsawImageSelectionDialogState
    extends State<JigsawImageSelectionDialog> {
  String? _selectedImagePath;
  // New list of actual jigsaw images
  final List<Map<String, String>> _jigsawImages = [
    {
      "path": "assets/images/jigsaw/landscape_mountain.jpg",
      "name": "Mountains"
    },
    {"path": "assets/images/jigsaw/landscape_beach.jpg", "name": "Beach"},
    {"path": "assets/images/jigsaw/animal_cat.jpg", "name": "Cat"},
    {"path": "assets/images/jigsaw/animal_bird.jpg", "name": "Bird"},
    {
      "path": "assets/images/jigsaw/abstract_colors.jpg",
      "name": "Abstract Colors"
    },
  ];

  void _selectImage(String path) {
    setState(() {
      _selectedImagePath = path;
    });
    // After selecting an image, show difficulty dialog
    _showDifficultyDialog();
  }

  void _showDifficultyDialog() {
    if (_selectedImagePath == null) return;

    showDialog<String>(
      context: context,
      barrierDismissible: false, // User must select a difficulty
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Difficulty'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _difficultyButton(context, 'Easy'),
              _difficultyButton(context, 'Medium'),
              _difficultyButton(context, 'Hard'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close difficulty dialog
                setState(() {
                  _selectedImagePath = null; // Reset image selection
                });
              },
            ),
          ],
        );
      },
    ).then((difficulty) {
      if (difficulty != null && _selectedImagePath != null) {
        // Pop the image selection dialog itself and return the result
        if (mounted) { // Check context.mounted
          Navigator.of(context).pop(
            JigsawSelectionResult(
              imagePath: _selectedImagePath!,
              difficulty: difficulty,
            ),
          );
        }
      } else {
        // If difficulty selection was cancelled, reset image selection
        // Check mounted for setState as well, good practice
        if (mounted) {
          setState(() {
            _selectedImagePath = null;
          });
        }
      }
    });
  }

  Widget _difficultyButton(BuildContext context, String difficulty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48), // Full width
        ),
        child: Text(difficulty),
        onPressed: () {
          Navigator.of(context).pop(difficulty); // Return selected difficulty
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If an image is already selected, the difficulty dialog is shown,
    // so this build method primarily focuses on showing the image selection.
    return AlertDialog(
      title: const Text('Select Jigsaw Image'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_selectedImagePath == null)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _jigsawImages.map((imageMap) {
                  final path = imageMap["path"]!;
                  final name = imageMap["name"]!;
                  return GestureDetector(
                    onTap: () => _selectImage(path),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(path),
                              fit: BoxFit.cover,
                              // Add an error builder for better UX if an image is missing
                              onError: (exception, stackTrace) {
                                debugPrint('Error loading image: $path, $exception');
                              },
                            ),
                            border: Border.all(
                              color: _selectedImagePath == path
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              width: _selectedImagePath == path ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // Display error inside the box if image fails to load
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error_outline, color: Colors.red, size: 40),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (_selectedImagePath != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Selected: ${_jigsawImages.firstWhere((img) => img["path"] == _selectedImagePath, orElse: () => {"name": "Unknown"})["name"]}\nNow choose difficulty...',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        if (_selectedImagePath == null) // Show cancel only if no image is selected yet
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close image selection dialog
            },
          ),
      ],
    );
  }
}

// Helper function to show the dialog (optional, can be called directly)
Future<JigsawSelectionResult?> showJigsawImageSelectionDialog(
    BuildContext context) {
  return showDialog<JigsawSelectionResult>(
    context: context,
    builder: (BuildContext context) {
      return const JigsawImageSelectionDialog();
    },
  );
}
