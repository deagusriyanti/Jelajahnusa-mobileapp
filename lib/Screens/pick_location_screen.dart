import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  /// DEFAULT LOCATION (PALEMBANG)
  LatLng selectedLocation = const LatLng(-2.9761, 104.7754);
  bool isSearching = false;

  /// SEARCH LOCATION INDONESIA
  Future<void> searchLocation() async {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) return;
    final query = "$searchText, Indonesia";
    setState(() {
      isSearching = true;
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&countrycodes=id&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'jelajah_nusa_app'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newLocation = LatLng(lat, lon);
          setState(() {
            selectedLocation = newLocation;
          });

          /// MOVE MAP TO SEARCH RESULT
          _mapController.move(newLocation, 13);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Location not found")));
        }
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    if (mounted) {
      setState(() {
        isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 5,

              /// TAP MAP
              onTap: (tapPosition, point) {
                setState(() {
                  selectedLocation = point;
                });

                /// MOVE CAMERA
                _mapController.move(point, _mapController.camera.zoom);
              },
            ),
            children: [
              /// MAP TILE
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                userAgentPackageName: 'com.example.jelajah_nusa',
              ),

              /// LOCATION MARKER
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// TOP SEARCH BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  /// BACK BUTTON
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// SEARCH FIELD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,

                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),

                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Search Indonesia location...",

                                hintStyle: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),

                              onSubmitted: (_) => searchLocation(),
                            ),
                          ),
                          isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  onPressed: searchLocation,
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.teal,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// SELECT BUTTON
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selectedLocation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Select Location",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
