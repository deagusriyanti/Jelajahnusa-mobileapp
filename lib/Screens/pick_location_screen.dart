import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() =>
      _PickLocationScreenState();
}

class _PickLocationScreenState
    extends State<PickLocationScreen> {
  final MapController _mapController =
      MapController();

  final TextEditingController _searchController =
      TextEditingController();

  /// DEFAULT LOCATION
  LatLng selectedLocation =
      const LatLng(-2.9761, 104.7754);

  bool isSearching = false;

  /// SEARCH LOCATION WORLDWIDE
  Future<void> searchLocation() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'jelajah_nusa_app',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          final lat =
              double.parse(data[0]['lat']);

          final lon =
              double.parse(data[0]['lon']);

          final newLocation =
              LatLng(lat, lon);

          setState(() {
            selectedLocation = newLocation;
          });

          /// MOVE MAP
          _mapController.move(
            newLocation,
            15,
          );
        } else {
          if (!mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Location not found",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isSearching = false;
    });
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

              /// TAP ANYWHERE
              onTap: (
                tapPosition,
                point,
              ) {
                setState(() {
                  selectedLocation = point;
                });
              },
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                userAgentPackageName:
                    'com.example.jelajah_nusa',
              ),

              /// MARKER
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
                      color: Colors.white,
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                        ),
                      ],
                    ),

                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: const Icon(
                        Icons.arrow_back,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// SEARCH FIELD
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                                  _searchController,

                              decoration:
                                  const InputDecoration(
                                border:
                                    InputBorder.none,

                                hintText:
                                    "Search location worldwide...",
                              ),

                              onSubmitted:
                                  (_) =>
                                      searchLocation(),
                            ),
                          ),

                          isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,

                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  onPressed:
                                      searchLocation,

                                  icon:
                                      const Icon(
                                    Icons.search,
                                    color:
                                        Colors.teal,
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

          /// BOTTOM BUTTON
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,

            child: SizedBox(
              height: 60,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    selectedLocation,
                  );
                },

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.teal,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                child: const Text(
                  "Select Location",

                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

