import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../util/constants.dart';

class MapScreen extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const MapScreen({super.key, required this.onLocationSelected});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = Set<Marker>();
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _checkLocationService();
  }

  Future<void> _checkLocationService() async {
    final serviceEnabled = await _location.serviceEnabled();

    if (!serviceEnabled) {
      if (! await _location.requestService()) {
        setState(() {
          _initialCameraPosition = const CameraPosition(target: LatLng(48, 13), zoom: 4);
        });
      } else {
        if (await Permission.locationWhenInUse.serviceStatus.isEnabled) {
          _getCurrentLocation();
        }
      }
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print("daa0");
      LocationData locationData = await _location.getLocation();
      print("ahhh $locationData");
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 14,
        );
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
            color: Colors.white,
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
    if (_markers.isNotEmpty) {
      LatLng selectedLocation = _markers.elementAt(0).position;
      widget.onLocationSelected(selectedLocation);
      Navigator.pop(context);
    }
  }

  Widget _buildMap() {
    return _initialCameraPosition == null
      ? const Center(child: CircularProgressIndicator(color: primaryColor,))
      : GoogleMap(
        onMapCreated: (controller) {
          setState(() {});
        },
        initialCameraPosition: _initialCameraPosition!,
        myLocationEnabled: true,
        markers: _markers,
        onTap: (LatLng location) {
          _addMarker(location);
        },
      );
  }

  void _addMarker(LatLng? location) async{

    setState(() {
      _markers.clear();

      if (location != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(location.toString()),
            position: location,
            infoWindow: const InfoWindow(title: 'Selected location'),
            icon: BitmapDescriptor.defaultMarker,
          )
        );
      }
    });
  }
}