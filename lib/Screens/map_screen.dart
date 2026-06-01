import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jelajah_nusa/Screens/route_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  Future<void> _openRoute() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.jelajahnusa',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 55,
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// BACK BUTTON
          SafeArea(
            child: Positioned(
              left: 20,
              top: 20,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.blueGrey,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),

          /// ROUTE BUTTON
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 18,
                  right: 18,
                ),
                child: ElevatedButton(
                  onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteScreen(
                            latitude: latitude,
                            longitude: longitude,
                            locationName: locationName,
                          ),
                        ),
                      );
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 5,
                    minimumSize: const Size(95, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Route',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// LOCATION CARD
          Positioned(
            left: 20,
            right: 20,
            bottom: 35,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}