import 'package:dio/dio.dart';

class RouteService {
  static const String apiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjgzNWE1MzU5ZmY4NDQ2OGE4ZmNlZWQ1MDk3NDgyZDEwIiwiaCI6Im11cm11cjY0In0=';

  static Future<Map<String, dynamic>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String profile,
  }) async {
    final dio = Dio();

    final response = await dio.get(
          'https://api.openrouteservice.org/v2/directions/$profile',
          options: Options(
            headers: {
              'Authorization': apiKey,
            },
          ),
          queryParameters: {
            'start': '$startLng,$startLat',
            'end': '$endLng,$endLat',
          },
        );

        print("STATUS : ${response.statusCode}");
        print("DATA : ${response.data}");

    return response.data;
  }
}