@echo off
echo Fish Accounts Flutter setup
echo.
echo 1. Make sure Flutter is installed and on PATH.
echo 2. Make sure Android Studio has Dart and Flutter plugins.
echo 3. Running flutter pub get...
flutter pub get
if errorlevel 1 goto :error
echo.
echo Setup complete. You can run:
echo   flutter run
echo or build:
echo   flutter build apk --debug
goto :end
:error
echo.
echo Setup failed. Run "flutter doctor" and fix the reported Android/Flutter issues.
:end
pause
