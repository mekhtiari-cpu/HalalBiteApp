import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Position? currentLocation;
  double? latitude;
  double? longitude;
  String? address;
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled. Please enable them.");
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            "Location permissions are permanently denied. Cannot access location.");
      }

      // Get the current position
      currentLocation = await Geolocator.getCurrentPosition();
      latitude = currentLocation?.latitude;
      longitude = currentLocation?.longitude;
      debugPrint("Latitude: $latitude, Longitude: $longitude");

      address = await getAddressFromLatLng(
          LatLng(currentLocation!.latitude, currentLocation!.longitude));
      debugPrint("Address: $address");

      return currentLocation;
    } catch (e) {
      debugPrint("getCurrent Location exception is $e");
      return null;
    }
  }

  Future<String> getAddressFromLatLng(LatLng? location) async {
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
          location!.latitude, location.longitude);

      Placemark place = placeMarks[0];

      String address = '';
      if (place.thoroughfare != null && place.thoroughfare != '') {
        address += '${place.thoroughfare}, ';
      }
      if (place.subLocality != null && place.subLocality != '') {
        address += '${place.subLocality}, ';
      }
      if (place.locality != null && place.locality != '') {
        address += '${place.locality}, ';
      }
      if (place.country != null && place.country != '') {
        address += '${place.country}';
      }
      // Remove any trailing commas or whitespace
      address = address.replaceAll(RegExp(r',\s*$'), '');
      return address;
    } catch (e) {
      debugPrint("@getAddressFromLatLng Error $e");

      return '';
    }
  }

  // getMarker(Driver driver, icon) async {
  //   var marker = Marker(
  //     icon: icon,
  //     position: LatLng(driver.latitude!, driver.longitude!),
  //     markerId: MarkerId('${driver.id}'),
  //     infoWindow: InfoWindow(title: '${driver.name}'),
  //   );

  //   return marker;
  // }

  distance(otherLat, otherLong, currentLat, currentLong) async {
    return await Geolocator.distanceBetween(
        otherLat, otherLong, currentLat, currentLong);
  }

  // getPreduction(String input) async {
  //   String requestUrl =
  //       '${EndPoints.baseURLForMap}?input=$input&inputtype=textquery&fields=formatted_address,place_id&key=${EndPoints.googleApiKey}';
  //   var response = await Dio().get(requestUrl);
  //   if (response.statusCode == 200) {
  //     print("Preduction   ${response.data}");
  //     return PrdicutionResponse.fromJson(response.data);
  //   }
  // }

  getLocationDetails(String placeId) async {
    // String request =
    //     '${EndPoints.placesBaseUrl}?placeid=$placeId&fields=geometry&key=${EndPoints.googleApiKey}';
    // var response = await Dio().get(request);
    // if (response.statusCode == 200) {
    //   return MapResponse.fromJson(response.data);
    // }
  }

  creatRootbetweenOriginAndDestination(
      LatLng fromLatLng, LatLng toLatLng) async {
    polylinePoints = PolylinePoints();
    polylines = {};
    polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: 'AIzaSyAFDOTJ9l1y84lAG9G-iFxEJ5uDLBLUKM4',
      request: PolylineRequest(
          origin: PointLatLng(fromLatLng.latitude, fromLatLng.longitude),
          destination: PointLatLng(toLatLng.latitude, toLatLng.longitude),
          mode: TravelMode.driving),
    );

    print("points ===> ${result.points.length}");
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print("Error ===> ${result.errorMessage}");
    }

    print("Polylines length ==>${polylineCoordinates.length}");

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: const PolylineId('poly'),
      color: Colors.blue,
      points: polylineCoordinates,
      width: 4,
    );

    // Adding the polyline to the map
    polylines.add(polyline);
    return polylines;
  }

  double calculateHaversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double dLat = (lat2 - lat1) * (3.141592653589793 / 180.0);
    double dLng = (lng2 - lng1) * (3.141592653589793 / 180.0);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1 * (3.141592653589793 / 180.0)) *
            cos(lat2 * (3.141592653589793 / 180.0)) *
            sin(dLng / 2) *
            sin(dLng / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  ///
  /// get estimate time and distance between two points
  ///
  // getTimeAndDistanceWithTolerance({
  //   required double fromLat,
  //   required double fromLong,
  //   required double toLat,
  //   required double toLong,
  // }) async
  // {
  //   const double toleranceInKm =
  //   0.0005; // Define the tolerance in kilometers(here it represent 5m )
  //   double haversineDistance =
  //   calculateHaversineDistance(fromLat, fromLong, toLat, toLong);
  //
  //   if (haversineDistance <= toleranceInKm && fromLat == toLat) {
  //     return GoogleMapDistanceAndTimeResponse(false);
  //   }
  //
  //   // Otherwise, make the API call
  //   // String requestUrl =
  //   //     '${EndPoints.timeAndDistanceUrl}?units=imperial&origins=$fromLat,$fromLong&destinations=$toLat,$toLong&key=${EndPoints.googleApiKey}';
  //   // var response = await Dio().get(requestUrl);
  //
  //   // print("response.statusCode: ${response.statusCode}");
  //
  //   // if (response.statusCode == 200) {
  //   //   return GoogleMapDistanceAndTimeResponse.fromJson(response.data);
  //   // }
  // }
  // Future<MapResponse> getLocationDetails(String placeId) async {
  //   String request =
  //       'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=AIzaSyA1fLuOd4HKKuvumMwh9qBcTqSdpIdPByg';

  //   var response = await Dio().get(request);

  //   if (response.statusCode == 200) {
  //     return MapResponse.fromJson(response.data);
  //   } else {
  //     return MapResponse(false, error: response.statusMessage);
  //   }
  // }

  // getTimeAndDistance(
  //     {double? fromLat,
  //       double? fromLong,
  //       double? toLat,
  //       double? toLong}) async {
  //   String requestUrl =
  //       'https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=$fromLat,$fromLong&destinations=$toLat,$toLong&key=AIzaSyAFDOTJ9l1y84lAG9G-iFxEJ5uDLBLUKM4';
  //
  //   ///TODO: Add google api key
  //   var response = await Dio().get(requestUrl);
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     debugPrint("GetTimeAndDistance Body ==> ${response.data.toString()}");
  //     return GoogleMapDistanceAndTimeResponse.fromJson(response.data);
  //   }
  // }
}
