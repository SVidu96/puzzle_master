1. Update the Version Code in pubspec.yaml
In your pubspec.yaml file, update the version field. The format is:
version: <version-name>+<version-code> - version: 1.0.3+2

2. Rebuild the App Bundle
After updating the version code, rebuild the app bundle:
flutter clean
flutter build appbundle --release

Built build\app\outputs\bundle\release\app-release.aab

To build the APK for your Flutter app, run the following command in your project directory:
flutter build apk --release
Built build\app\outputs\flutter-apk\app-release.apk

To install an APK on the Android emulator, use the following command in your terminal:
adb install <path-to-apk>
adb install build/app/outputs/flutter-apk/app-release.apk
OR
flutter install (Make sure your emulator is running.)
