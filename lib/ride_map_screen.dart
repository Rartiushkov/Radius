// 📄 ride_map_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  StreamSubscription<LocationData>? _locSub;
  Timer? _movementTimer;
  BitmapDescriptor? _specialistIcon;
  bool _isRequesting = false;
  bool _specialistAssigned = false;
  bool _locationConfirmed = false;
  String? _requestDocId;



  // Only a single specialist is shown on the map. Additional demo
  // markers were removed so users don't see multiple moving points.
  final List<_Specialist> _specialists = [
    _Specialist(id: '1', position: const LatLng(37.4275, -122.0840)),
  ];


  @override
  void initState() {
    super.initState();
    _loadSpecialistIcon();
    _checkExistingRequest().then((_) => _initLocation());
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

    try {
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(24, 24)),
        asset,
      );
      if (!mounted) return;
      setState(() {
        _specialistIcon = icon;
      });
    } catch (e) {
      debugPrint('Failed to load specialist icon: $e');
    }


  }

  Future<void> _checkExistingRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final query = await FirebaseFirestore.instance
        .collection("requests")
        .where("userId", isEqualTo: uid)
        .where("status", whereIn: ["pending", "assigned"])
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      _requestDocId = query.docs.first.id;
      _clientLocation ??= LocationData.fromMap({
        "latitude": data["latitude"],
        "longitude": data["longitude"],
      });
      final status = data["status"] as String? ?? "pending";
      setState(() {
        _locationConfirmed = true;
        _isRequesting = status == "pending";
        _specialistAssigned = status == "assigned";
      });
      if (status == "assigned") {
        _startSpecialistMovement();
      }
    }
  }

  Future<void> _checkExistingRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final query = await FirebaseFirestore.instance
        .collection("requests")
        .where("userId", isEqualTo: uid)
        .where("status", whereIn: ["pending", "assigned"])
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      _requestDocId = query.docs.first.id;
      _clientLocation ??= LocationData.fromMap({
        "latitude": data["latitude"],
        "longitude": data["longitude"],
      });
      final status = data["status"] as String? ?? "pending";
      setState(() {
        _locationConfirmed = true;
        _isRequesting = status == "pending";
        _specialistAssigned = status == "assigned";
      });
      if (status == "assigned") {
        _startSpecialistMovement();
      }
    }
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

      if (_clientLocation == null) {
        setState(() {
          _clientLocation = locData;
          _locationConfirmed = true;
        });
      }

      _locSub = _location.onLocationChanged.listen((newLoc) {
        if (!_isRequesting && !_specialistAssigned) {
          setState(() {
            _clientLocation = newLoc;
            _locationConfirmed = true;
          });
        }
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _clientLocation = null;
      });
    }
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

  Future<void> _requestSpecialist() async {
    if (_clientLocation == null) return;

    setState(() {
      _isRequesting = true;
    });

    try {

      final doc = await FirebaseFirestore.instance.collection("requests").add({

        'userId': FirebaseAuth.instance.currentUser?.uid,
        'latitude': _clientLocation!.latitude,
        'longitude': _clientLocation!.longitude,
        'serviceType': widget.serviceType,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _requestDocId = doc.id;

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log request: $e')),
        );
      }
    }

    await Future.delayed(const Duration(seconds: 3));
    if (_requestDocId != null) {
      await FirebaseFirestore.instance
          .collection("requests")
          .doc(_requestDocId)
          .update({"status": "assigned"});
    }
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _specialistAssigned = true;
    });
    _startSpecialistMovement();
  }
  Future<void> _cancelRequest() async {
    _movementTimer?.cancel();
    if (_requestDocId != null) {
      await FirebaseFirestore.instance
          .collection("requests")
          .doc(_requestDocId)
          .update({"status": "canceled"});
      _requestDocId = null;
    }
    if (mounted) {
      setState(() {
        _isRequesting = false;
        _specialistAssigned = false;
      });
    }
  }


  @override
  void dispose() {
    _movementTimer?.cancel();
    _locSub?.cancel();
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
        title: Text(_specialistAssigned
            ? '${widget.serviceType} on the way'
            : 'Request ${widget.serviceType}'),
      ),

      body: Stack(
        children: [
          GoogleMap(
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
                _locationConfirmed = false;
              });
            },
            markers: _buildMarkers(clientLatLng),
            polylines: _buildPolylines(clientLatLng),
          ),
          if (_isRequesting)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_locationConfirmed &&
                    !_specialistAssigned &&
                    !_isRequesting)
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _locationConfirmed = true);
                    },
                    child: const Text('Confirm Location'),
                  ),
                if (_locationConfirmed)
                  ElevatedButton(
                    onPressed: _specialistAssigned || _isRequesting
                        ? null
                        : _requestSpecialist,
                    child: Text(
                      _specialistAssigned
                          ? 'Specialist en route'
                          : 'Request Specialist',
                    ),
                  ),

                if (_isRequesting || _specialistAssigned)
                  const SizedBox(height: 8),
                if (_isRequesting || _specialistAssigned)
                  ElevatedButton(
                    onPressed: _cancelRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text('Cancel'),
                  ),

              ],
            ),
          ),
        ],

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


    if (_specialistAssigned) {
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

    }

    return markers;
  }

  Set<Polyline> _buildPolylines(LatLng clientLatLng) {
    final Set<Polyline> lines = {};

    if (_specialistAssigned) {
      int idx = 0;
      for (var specialist in _specialists) {
        lines.add(Polyline(
          polylineId: PolylineId('line_${idx++}'),
          points: [specialist.position, clientLatLng],
          color: Colors.blueAccent,
          width: 3,
        ));
      }

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
