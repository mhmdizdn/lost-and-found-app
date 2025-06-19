import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(-6.2088, 106.8456); // Default to Jakarta
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedPosition = LatLng(position.latitude, position.longitude);
          _updateMarker(_selectedPosition);
        });
        
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_selectedPosition),
          );
        }
      }
    } catch (e) {
      // Handle error silently, keep default location
    }
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location', style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple[100],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedPosition);
            },
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _selectedPosition,
          zoom: 15,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onTap: _updateMarker,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        height: 80,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Tap on the map to select a location',
                style: GoogleFonts.poppins(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedPosition);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text('Confirm', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
} 