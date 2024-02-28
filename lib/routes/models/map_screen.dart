import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../config.dart';
import '../../util/constants.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapScreen extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const MapScreen({super.key, required this.onLocationSelected});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationData? _currentLocation;
  Set<Marker> _markers = Set<Marker>();
  // List<LatLng> _polylineCoordinates = [];

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
    return GoogleMap(
      onMapCreated: (controller) {
        setState(() {});
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(0.0, 0.0),
        zoom: 2,
      ),
      myLocationEnabled: true,
      // polylines: {
      //   Polyline(
      //     polylineId: const PolylineId("route"),
      //     points: _polylineCoordinates,
      //     color: primaryColor,
      //     width: 6,
      //   )
      // },
      markers: _markers,
      onTap: (LatLng location) {
        _addMarker(location);
      },
    );
  }

  void _addMarker(LatLng? location) async{
    // PolylinePoints polylinePoints = PolylinePoints();

    setState(() {
      _markers.clear();
      // _polylineCoordinates.clear();

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

    // if (_currentLocation != null) {
    //   PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    //     Config.googleApiKey,
    //     PointLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
    //     PointLatLng(location!.latitude, location.longitude),
    //   );
    //
    //   if (result.points.isNotEmpty) {
    //     result.points.forEach(
    //       (PointLatLng point) => _polylineCoordinates.add(
    //         LatLng(point.latitude, point.longitude)
    //       )
    //     );
    //     setState(() {});
    //   }
    // }
  }
}