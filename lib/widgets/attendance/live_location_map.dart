import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:absen_cmi/config/api_config.dart';

class LiveLocationMap extends StatefulWidget {
  final Function(bool) onLocationStatusChanged;

  const LiveLocationMap({Key? key, required this.onLocationStatusChanged})
      : super(key: key);

  @override
  _LiveLocationMapState createState() => _LiveLocationMapState();
}

class _LiveLocationMapState extends State<LiveLocationMap> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _isMapReady = false;
  bool _isMockLocation = false;
  double _distanceToOffice = 0;

  // Office location coordinates
  static final LatLng officeLocation = LatLng(
    ApiConfig.officeLatitude,
    ApiConfig.officeLongitude,
  ); // Using coordinates from config
  static const double officeRadius = 50; // 50 meters radius

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Function to handle all the location permission logic
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog to enable location services
        if (mounted) {
          _showErrorDialog(
            'Location services are disabled. Please enable location services.',
          );
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showErrorDialog('Location permissions are denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showErrorDialog(
            'Location permissions are permanently denied. Please enable them in app settings.',
          );
        }
        return;
      }

      // When we reach here, permissions are granted and we can continue
      await _getCurrentLocation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error getting location: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Get position with additional checks
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Check for mock location
      bool isMockLocation = await _checkMockLocation(position);

      if (isMockLocation) {
        if (mounted) {
          setState(() {
            _isMockLocation = true;
            _isLoading = false;
          });
          _showErrorDialog(
            'Fake GPS detected. Please disable mock locations and try again.',
          );
          widget.onLocationStatusChanged(false);
          return;
        }
      }

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
          _isMockLocation = false;
        });

        // Calculate distance and update status
        _checkLocationStatus();

        // Only move camera if map is ready
        if (_isMapReady && _currentLocation != null) {
          _mapController.move(_currentLocation!, 15);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error getting current location: $e');
      }
    }
  }

  Future<bool> _checkMockLocation(Position position) async {
    try {
      // Check if location is mocked
      bool isMocked = position.isMocked;

      // Additional checks for suspicious behavior
      if (!isMocked) {
        // Check for sudden large position changes
        if (_currentLocation != null) {
          double distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            position.latitude,
            position.longitude,
          );

          // If position changed more than 100 meters in 5 seconds, it's suspicious
          if (distance > 100) {
            return true;
          }
        }

        // Check for unrealistic accuracy
        if (position.accuracy > 100) {
          return true;
        }
      }

      return isMocked;
    } catch (e) {
      return true; // If we can't verify, assume it's fake
    }
  }

  void _checkLocationStatus() {
    if (_currentLocation != null && !_isMockLocation) {
      // Calculate distance between current location and office
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        officeLocation.latitude,
        officeLocation.longitude,
      );

      setState(() {
        _distanceToOffice = distance;
      });

      // Check if within office radius (50 meters)
      final isInOffice = distance <= officeRadius;

      // Notify parent widget about location status
      widget.onLocationStatusChanged(isInOffice);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null || _isMockLocation
              ? const Center(child: Text('Unable to get current location'))
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation!,
                          initialZoom: 15,
                          minZoom: 0,
                          maxZoom: 19,
                          onMapReady: () {
                            setState(() {
                              _isMapReady = true;
                            });
                            // Move to current location once map is ready
                            if (_currentLocation != null) {
                              _mapController.move(_currentLocation!, 15);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.absen_cmi',
                            maxZoom: 19,
                          ),
                          CurrentLocationLayer(),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: officeLocation,
                                radius: officeRadius,
                                color: Colors.blue.withOpacity(0.3),
                                borderColor: Colors.blue,
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'officeLocation',
                        onPressed: () {
                          _mapController.move(officeLocation, 15);
                        },
                        child: const Icon(Icons.business),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'currentLocation',
                        onPressed: () {
                          if (_currentLocation != null) {
                            _mapController.move(_currentLocation!, 15);
                          }
                        },
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Jarak ke kantor: ${(_distanceToOffice / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
