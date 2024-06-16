import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:nominatim_flutter/model/request/reverse_request.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import '../../util/constants.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const MapScreen({super.key, required this.onLocationSelected, this.initialLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = Set<Marker>();
  final Location _location = Location();
  late TextEditingController _searchController;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  String? _currentCountryCode;

  @override
  void initState() {
    super.initState();
    _markers.add(widget.initialLocation as Marker);
    _searchController = TextEditingController();
    _checkLocationService();
  }

  Future<void> _checkLocationService() async {
    final serviceEnabled = await _location.serviceEnabled();

    if (!serviceEnabled) {
      if (!await _location.requestService()) {
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
      LocationData locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _initialCameraPosition = CameraPosition(
          target: _currentLocation!,
          zoom: 14,
        );
      });
      await _getCurrentCountryCode();
    } catch (e) {
      Exception('Error getting location: $e');
    }
  }

  Future<void> _getCurrentCountryCode() async {
    if (_currentLocation == null) return;

    final reverseRequest = ReverseRequest(
      lat: _currentLocation!.latitude,
      lon: _currentLocation!.longitude,
    );

    try {
      final response = await NominatimFlutter.instance.reverse(
        reverseRequest: reverseRequest,
        language: 'en-US,en;q=0.5',
      );

      final address = response.address;
      setState(() {
        _currentCountryCode = address?['country_code'] as String?;
      });

      print('Current country code: $_currentCountryCode');
    } catch (e) {
      Exception('Error fetching country code: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (_currentLocation == null || _currentCountryCode == null) {
      return [];
    }
    final lat = _currentLocation!.latitude;
    final lon = _currentLocation!.longitude;

    // final viewbox = ViewBox(lat - 0.1, lat + 0.1, lon - 0.1, lon + 0.1);

    final response = await NominatimFlutter.instance.search(
      searchRequest: SearchRequest(
        query: query,
        limit: 10,
        countryCodes: [_currentCountryCode!],
        // viewBox: viewbox,
      ),
      language: 'en-US,en;q=0.5',
    );

    if (response.isNotEmpty) {
      final result = response.map<Map<String, dynamic>>((place) {
        return {
          'display_name': place.displayName,
          'lat': place.lat,
          'lon': place.lon,
        };
      }).toList();
      return result;
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'Add Destination',
          style: TextStyle(
            fontFamily: font1,
            fontSize: 23,
            color: Colors.black,
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
      body: Stack(
        children: [
          _buildMap(),
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.only(left: 5, right: 55, top: 5),
            child: TypeAheadField(
              controller: _searchController,
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: false,
                style: DefaultTextStyle.of(context).style.copyWith(fontStyle: FontStyle.italic),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    borderSide: BorderSide(color: Colors.transparent, width: 2.5),
                  ),
                  hintText: 'Search Places',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await _searchPlaces(pattern);
              },
              itemBuilder: (context, Map<String, dynamic> suggestion) {
                return ListTile(
                  title: Text(suggestion['display_name']),
                );
              },
              onSelected: (Map<String, dynamic> suggestion) {
                final lat = double.parse(suggestion['lat']);
                final lon = double.parse(suggestion['lon']);
                final latLng = LatLng(lat, lon);
                _addMarker(latLng);
                _moveCamera(latLng);
              },
              decorationBuilder: (context, child) => Material(
                type: MaterialType.card,
                elevation: 4,
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white.withOpacity(0.9),
                child: child,
              ),
            ),
          ),
        ],
      ),
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
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
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

  void _addMarker(LatLng location) async {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(location.toString()),
          position: location,
          infoWindow: const InfoWindow(title: 'Selected location'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  void _moveCamera(LatLng location) async {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(location));
    }
  }
}
