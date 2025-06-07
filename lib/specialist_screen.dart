import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'user_account_screen.dart';

class SpecialistScreen extends StatefulWidget {
  const SpecialistScreen({super.key});

  @override
  _SpecialistScreenState createState() => _SpecialistScreenState();
}

class _SpecialistScreenState extends State<SpecialistScreen> {
  late GoogleMapController _mapController;
  final Location _location = Location();
  LatLng? _specialistLocation;
  LatLng _clientLocation = const LatLng(37.42796133580664, -122.085749655962);
  bool _isOrderAccepted = false;
  Timer? _movementTimer;
  Set<Polyline> _lines = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final locData = await _location.getLocation();
      setState(() {
        _specialistLocation = LatLng(locData.latitude!, locData.longitude!);
      });
      _updatePolyline();
      _startSpecialistMovement();
    } catch (e) {
      print('Location error: $e');
    }
  }

  void _startSpecialistMovement() {
    if (_specialistLocation == null) return;
    _movementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _specialistLocation = LatLng(
          _specialistLocation!.latitude + 0.0001,
          _specialistLocation!.longitude - 0.0001,
        );
        _updatePolyline();
      });
    });
  }

  void _updatePolyline() {
    if (_specialistLocation == null) return;
    _lines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_specialistLocation!, _clientLocation],
        color: Colors.blueAccent,
        width: 3,
      )
    };
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const UserAccountScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_specialistLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Specialist Dashboard')),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -10) {
            _openProfile();
          }
        },
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _specialistLocation!, zoom: 14),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(markerId: const MarkerId('specialist'), position: _specialistLocation!, infoWindow: const InfoWindow(title: 'Specialist')),
                Marker(markerId: const MarkerId('client'), position: _clientLocation, infoWindow: const InfoWindow(title: 'Client')),
              },
              polylines: _lines,
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _isOrderAccepted ? null : () => setState(() => _isOrderAccepted = true),
                child: Text(_isOrderAccepted ? 'Order Accepted' : 'Accept Order'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.logout),
      ),
    );
  }
}