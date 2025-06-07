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

  // Only a single specialist is shown on the map. Additional demo
  // markers were removed so users don't see multiple moving points.
  final List<_Specialist> _specialists = [
    _Specialist(id: '1', position: const LatLng(37.4275, -122.0840)),
  ];


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

    // Load the custom marker at a smaller size so the picture doesn't
    // cover too much of the map UI.
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(40, 40)),

      asset,
    );
    setState(() {
      _specialistIcon = icon;
    });
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      final locData = await _location.getLocation();
      setState(() {
        _clientLocation = locData;
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _clientLocation = null;
      });
    }
    _startSpecialistMovement();
  }

  void _startSpecialistMovement() {
    if (_clientLocation == null) return;
    _movementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        for (var specialist in _specialists) {
          specialist.moveTowards(_clientLocation!);
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
    if (_clientLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final LatLng clientLatLng = LatLng(
      _clientLocation!.latitude!,
      _clientLocation!.longitude!,
    );

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
