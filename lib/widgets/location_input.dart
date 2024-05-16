import 'package:assignment_map/models/place.dart';
import 'package:assignment_map/screens/map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectLocation});

  final void Function(PlaceLocation location) onSelectLocation;

  @override
  State<LocationInput> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  //Location? _pickedLocation;
  PlaceLocation? _pickedLocation;
  var _isGettingLocation = false;

  String get locationImage {
    // a getter which will return String
    if (_pickedLocation == null) {
      return '';
    }
    final lat = _pickedLocation!.latitude;
    final lng = _pickedLocation!.longitude;
    return 'https://maps.googleapis.com/maps/api/staticmap?center$lat,$lng=&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:AS%7C$lat,$lng&key=AIzaSyB0-r6_RStUCPN-kFz1C4EK6nYjWbqw7NQ';
  }

  void _savePlace(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=AIzaSyB0-r6_RStUCPN-kFz1C4EK6nYjWbqw7NQ');
    final response =
        await http.get(url); //get method is used for send request to http
    final resData = json.decode(response.body);
    final address = resData['results'][0]['formatted_address'];

    setState(() {
      _pickedLocation = PlaceLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      _isGettingLocation = false;
    });

    widget.onSelectLocation(_pickedLocation!);
  }

  void _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      _isGettingLocation = true;
    });

    locationData = await location.getLocation();
    final lat = locationData.latitude;
    final lng = locationData.longitude;

    if (lat == null || lng == null) {
      return;
    }

    _savePlace(lat, lng);

    print(locationData.latitude);
    print(locationData.longitude);
  }

  void _SelectOnMap() async {
    final pickedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );

    if (pickedLocation == null) {
      return;
    }
    _savePlace(
      pickedLocation.latitude,
      pickedLocation.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = Text(
      'No Location Choosen',
      style: Theme.of(context)
          .textTheme
          .bodyLarge!
          .copyWith(color: Theme.of(context).colorScheme.onBackground),
      textAlign: TextAlign.center,
    );

    if (_pickedLocation != null) {
      previewContent = Image.network(
        locationImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    }

    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: previewContent,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
            ),
            TextButton.icon(
              onPressed: () {
                _SelectOnMap();
              },
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
            ),
          ],
        )
      ],
    );
  }
}
