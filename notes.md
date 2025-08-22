# Команды для Flutter-проекта

## Сборка и установка
# Установка debug-версии на подключенное устройство
flutter run

# Сборка и установка release-версии
flutter build apk --release

# Установка release-версии через adb
adb install build/app/outputs/flutter-apk/app-release.apk

## Проверка и анализ
# Поиск утечек памяти
flutter pub get

# Проверка на ошибки и стилистику
flutter analyze