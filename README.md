# Карта общественного транспорта Новосибирска

Мобильное приложение на Flutter для отображения карты общественного транспорта Новосибирска.

## Возможности

- Просмотр всех маршрутов общественного транспорта (автобусы, троллейбусы, трамваи, маршрутки)
- Отображение маршрутов на карте Yandex Maps
- Отображение транспорта в реальном времени
- Отображение остановок на карте
- Добавление маршрутов в избранное
- Просмотр информации о транспорте при клике на маркер
- Просмотр названия остановки при клике на остановку

## Установка

1. Установите зависимости:
```bash
flutter pub get
```

2. Настройте Yandex MapKit:
   - Получите API ключ на https://developer.tech.yandex.ru/
   - Для Android: добавьте ключ в `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.yandex.mapkit.api_key"
       android:value="YOUR_API_KEY"/>
   ```
   - Для iOS: добавьте ключ в `ios/Runner/Info.plist`:
   ```xml
   <key>YANDEX_MAPKIT_API_KEY</key>
   <string>YOUR_API_KEY</string>
   ```

3. Создайте иконки для карты:
   - Создайте папку `assets/` в корне проекта
   - Добавьте иконки:
     - `assets/stop_marker.png` - иконка остановки (красный круг, 24x24px)
     - `assets/bus_marker.png` - иконка транспорта (синий прямоугольник, 24x24px)
   - Обновите `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/stop_marker.png
       - assets/bus_marker.png
   ```

4. Запустите приложение:
```bash
flutter run
```

## Структура проекта

- `lib/models/` - модели данных (маршруты, маркеры, пути)
- `lib/services/` - сервисы (API, избранное)
- `lib/screens/` - экраны приложения
- `lib/utils/` - утилиты

## API

Приложение использует API Новосибирского городского транспорта:
- Список маршрутов: https://map.nskgortrans.ru/listmarsh.php?r&r=false
- Маркеры транспорта: https://map.nskgortrans.ru/markers.php?r={type}-{marsh}-W-{name}
- Путь маршрута: https://map.nskgortrans.ru/trasses.php?r={type}-{marsh}-W-{name}

## Зависимости

- `yandex_mapkit` - карты Yandex
- `http` - HTTP запросы
- `shared_preferences` - хранение избранного
- `provider` - управление состоянием
