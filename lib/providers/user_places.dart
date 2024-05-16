import 'dart:io';
import 'package:assignment_map/models/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<Database> _getDatabase() async {
    //1
    final dbPath = await sql.getDatabasesPath();
    final db = await sql.openDatabase(
      path.join(dbPath, 'places.db'),
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE user_places(id TEXT PRIMARY KEY, title TEXT, lat REAL, lng REAL, address TEXT)');
      },
      version: 1,
    );
    return db;
  }

  Future<void> loadPlaces() async {
    //2
    final db = await _getDatabase();
    final data = await db.query('user_places');
    final places = data
        .map(
          (Row) => Place(
            id: Row['id'] as String,
            title: Row['title'] as String,
            // image: File(Row['image'] as String),
            location: PlaceLocation(
              latitude: Row['lat'] as double,
              longitude: Row['lng'] as double,
              address: Row['address'] as String,
            ),
          ),
        )
        .toList();
    state = places;
  }

  void addPlace(String title, PlaceLocation location) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory(); //3

    final newPlace = Place(title: title, location: location); //initially

    final db = await _getDatabase(); //4
    db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.title,
      // 'image': newPlace.image.path,
      'lat': newPlace.location.latitude,
      'lng': newPlace.location.longitude,
      'address': newPlace.location.address,
    }); //4

    state = [newPlace, ...state]; //initially
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
  (ref) => UserPlacesNotifier(),
);
