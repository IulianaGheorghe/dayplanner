import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'constants.dart';

class MapScreen extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const MapScreen({super.key, required this.onLocationSelected});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationData? _currentLocation;
  Set<Marker> _markers = Set<Marker>();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();

    try {
      LocationData locationData = await location.getLocation();
      setState(() {
        _currentLocation = locationData;
        _addMarker(const LatLng(0.0, 0.0));
      });
    } catch (e) {
      Exception('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text('Add Destination',
          style: TextStyle(
              fontFamily: font1,
              fontSize: 23,
              color: Colors.black
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            color: Colors.yellow,
            onPressed: () {
              _saveDestination();
            },
          ),
        ],
      ),
      body: _buildMap(),
    );
  }

  void _saveDestination() async {
    if (_markers.length >= 2) {
      LatLng selectedLocation = _markers.elementAt(1).position;
      widget.onLocationSelected(selectedLocation);
      Navigator.pop(context);
    }
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GoogleMap(
      onMapCreated: (controller) {
        setState(() {
        });
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        ),
        zoom: 14,
      ),
      markers: _markers,
      onTap: (LatLng location) {
        _addMarker(location);
      },
    );
  }

  Marker _newMarker(LatLng location, icon, text) {
    Marker newMarker = Marker(
      markerId: MarkerId(location.toString()),
      position: location,
      infoWindow: InfoWindow(title: text),
      icon: icon,
    );

    return newMarker;
  }

  void _addMarker(LatLng location) {
    setState(() {
      _markers.clear();
      _markers.add(
        _newMarker(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!,),
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          'Current location'
        )
      );
      if (location != const LatLng(0.0, 0.0)) {
        _markers.add(
            _newMarker(
                location,
                BitmapDescriptor.defaultMarker,
                'Selected location'
            )
        );
      }
    });
  }
}