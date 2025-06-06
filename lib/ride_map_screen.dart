// 📄 ride_map_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class RideMapScreen extends StatefulWidget {
  final String serviceType;

  const RideMapScreen({super.key, required this.serviceType});

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  late GoogleMapController _mapController;
  LocationData? _clientLocation;
  final Location _location = Location();
  Timer? _movementTimer;
  BitmapDescriptor? _specialistIcon;

  final List<_Specialist> _specialists = [
    _Specialist(id: '1', position: const LatLng(37.4275, -122.0840)),
    _Specialist(id: '2', position: const LatLng(37.4285, -122.0850)),
    _Specialist(id: '3', position: const LatLng(37.4265, -122.0830)),
  ];

  static const LatLng defaultLocation = LatLng(37.4219999, -122.0840575); // Googleplex

  @override
  void initState() {
    super.initState();
    _loadSpecialistIcon();
    _initLocation();
  }

  Future<void> _loadSpecialistIcon() async {
    String asset;
    switch (widget.serviceType.toLowerCase()) {
      case 'doctor':
        asset = 'assets/images/doctor.png';
        break;
      case 'mechanic':
        asset = 'assets/images/mechanic.png';
        break;
      case 'lawyer':
        asset = 'assets/images/lawyer.png';
        break;
      default:
        asset = 'assets/images/specialist.png';
    }
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      asset,
    );
    setState(() {
      _specialistIcon = icon;
    });
  }

  Future<void> _initLocation() async {
    try {
      final locData = await _location.getLocation();
      setState(() {
        _clientLocation = locData;
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _clientLocation = LocationData.fromMap({
          "latitude": defaultLocation.latitude,
          "longitude": defaultLocation.longitude,
        });
      });
    }
    _startSpecialistMovement();
  }

  void _startSpecialistMovement() {
    _movementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        for (var specialist in _specialists) {
          specialist.moveTowards(_clientLocation ?? LocationData.fromMap({
            "latitude": defaultLocation.latitude,
            "longitude": defaultLocation.longitude,
          }));
        }
      });
    });
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng clientLatLng = _clientLocation != null
        ? LatLng(_clientLocation!.latitude ?? defaultLocation.latitude,
        _clientLocation!.longitude ?? defaultLocation.longitude)
        : defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serviceType} is on the way'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: clientLatLng,
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
        onTap: (LatLng pos) {
          setState(() {
            _clientLocation = LocationData.fromMap({
              'latitude': pos.latitude,
              'longitude': pos.longitude,
            });
          });
        },
        markers: _buildMarkers(clientLatLng),
        polylines: _buildPolylines(clientLatLng),
      ),
    );
  }

  Set<Marker> _buildMarkers(LatLng clientLatLng) {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('client'),
        position: clientLatLng,
        infoWindow: const InfoWindow(title: 'You'),
      )
    };

    for (var specialist in _specialists) {
      markers.add(
        Marker(
          markerId: MarkerId('specialist_${specialist.id}'),
          position: specialist.position,
          infoWindow: InfoWindow(title: 'Specialist ${specialist.id}'),
          icon: _specialistIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(LatLng clientLatLng) {
    final Set<Polyline> lines = {};
    int idx = 0;
    for (var specialist in _specialists) {
      lines.add(Polyline(
        polylineId: PolylineId('line_${idx++}'),
        points: [specialist.position, clientLatLng],
        color: Colors.blueAccent,
        width: 3,
      ));
    }
    return lines;
  }
}

class _Specialist {
  final String id;
  LatLng position;

  _Specialist({required this.id, required this.position});

  void moveTowards(LocationData? clientLocation) {
    if (clientLocation == null) return;

    final double dx = (clientLocation.latitude! - position.latitude);
    final double dy = (clientLocation.longitude! - position.longitude);

    position = LatLng(
      position.latitude + 0.0005 * dx.sign,
      position.longitude + 0.0005 * dy.sign,
    );
  }
}
