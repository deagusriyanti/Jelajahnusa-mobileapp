import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RouteScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const RouteScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  static const String apiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjgzNWE1MzU5ZmY4NDQ2OGE4ZmNlZWQ1MDk3NDgyZDEwIiwiaCI6Im11cm11cjY0In0=";

  LatLng? currentLocation;

  List<LatLng> routePoints = [];

  bool loading = true;

  double distanceKm = 0;
  double durationHour = 0;

  String carEstimate = "-";
  String motorEstimate = "-";
  String walkEstimate = "-";
  String trainEstimate = "-";
  String planeEstimate = "-";

  @override
  void initState() {
    super.initState();
    initializeRoute();
  }

  Future<void> initializeRoute() async {
    await getCurrentLocation();

    if (currentLocation != null) {
      await getDrivingRoute();
      await getWalkingRoute();
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return;
    }

    final pos =
        await Geolocator.getCurrentPosition();

    currentLocation = LatLng(
      pos.latitude,
      pos.longitude,
    );
  }

  Future<void> getDrivingRoute() async {
    try {
      final dio = Dio();

      final response = await dio.get(
        "https://api.openrouteservice.org/v2/directions/driving-car",
        queryParameters: {
          "api_key": apiKey,
          "start":
              "${currentLocation!.longitude},${currentLocation!.latitude}",
          "end":
              "${widget.longitude},${widget.latitude}",
        },
      );

      final feature =
          response.data["features"][0];

      final summary =
          feature["properties"]["summary"];

      distanceKm =
          summary["distance"] / 1000;

      durationHour =
          summary["duration"] / 3600;

      carEstimate =
          convertDuration(summary["duration"]);

      motorEstimate =
          convertDuration(
            summary["duration"] * 0.9,
          );

      final coordinates =
          feature["geometry"]["coordinates"];

      routePoints =
          coordinates.map<LatLng>((coord) {
        return LatLng(
          coord[1].toDouble(),
          coord[0].toDouble(),
        );
      }).toList();

      calculateTrainAndPlane();
    } catch (e) {
        print("ERROR ROUTE:");
        print(e);
      }
  }

  Future<void> getWalkingRoute() async {
    try {
      final dio = Dio();

      final response = await dio.get(
        "https://api.openrouteservice.org/v2/directions/foot-walking",
        queryParameters: {
          "api_key": apiKey,
          "start":
              "${currentLocation!.longitude},${currentLocation!.latitude}",
          "end":
              "${widget.longitude},${widget.latitude}",
        },
      );

      final feature =
          response.data["features"][0];

      walkEstimate =
          convertDuration(
            feature["properties"]["summary"]
                ["duration"],
          );
    } catch (e) {
      walkEstimate = "Tidak tersedia";
    }
  }

  void calculateTrainAndPlane() {
    if (distanceKm < 100) {
      trainEstimate = "Tidak tersedia";
      planeEstimate = "Tidak tersedia";
      return;
    }

    final trainHours =
        distanceKm / 80;

    final planeHours =
        distanceKm / 700;

    trainEstimate =
        convertDuration(trainHours * 3600);

    planeEstimate =
        convertDuration(planeHours * 3600);
  }

  String convertDuration(
    double seconds,
  ) {
    final duration =
        Duration(seconds: seconds.round());

    final days = duration.inDays;
    final hours =
        duration.inHours.remainder(24);
    final minutes =
        duration.inMinutes.remainder(60);

    if (days > 0) {
      return "$days hari $hours jam";
    }

    return "$hours jam $minutes menit";
  }

  Widget transportTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(
      widget.latitude,
      widget.longitude,
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFFEAF8FA),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        destination,
                    initialZoom: 7,
                  ),

                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName:
                          "com.example.jelajah_nusa",
                    ),

                    if (routePoints
                        .isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points:
                                routePoints,
                            strokeWidth: 5,
                            color:
                                Colors.blue,
                          ),
                        ],
                      ),

                    MarkerLayer(
                      markers: [
                        if (currentLocation !=
                            null)
                          Marker(
                            point:
                                currentLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons
                                  .my_location,
                              color:
                                  Colors.blue,
                              size: 30,
                            ),
                          ),

                        Marker(
                          point:
                              destination,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons
                                .location_on,
                            color:
                                Colors.red,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(20),
                    child: CircleAvatar(
                      backgroundColor:
                          Colors.white,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        icon: const Icon(
                          Icons
                              .arrow_back,
                        ),
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment:
                      Alignment
                          .bottomCenter,
                  child: Container(
                    margin:
                        const EdgeInsets
                            .all(20),
                    padding:
                        const EdgeInsets
                            .all(20),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors
                              .black12,
                          blurRadius:
                              10,
                        ),
                      ],
                    ),
                    child:
                        SingleChildScrollView(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          Text(
                            widget
                                .locationName,
                            style:
                                const TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                              height: 10),

                          Text(
                            "Jarak ${distanceKm.toStringAsFixed(1)} km",
                          ),

                          const SizedBox(
                              height: 20),

                          transportTile(
                            Icons
                                .directions_car,
                            "Mobil",
                            carEstimate,
                          ),

                          transportTile(
                            Icons
                                .motorcycle,
                            "Motor",
                            motorEstimate,
                          ),

                          transportTile(
                            Icons
                                .directions_walk,
                            "Pejalan Kaki",
                            walkEstimate,
                          ),

                          transportTile(
                            Icons.train,
                            "Kereta",
                            trainEstimate,
                          ),

                          transportTile(
                            Icons.flight,
                            "Pesawat",
                            planeEstimate,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}