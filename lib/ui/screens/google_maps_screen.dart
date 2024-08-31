import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../../constants.dart';

class GoogleMapsScreen extends StatefulWidget {
  const GoogleMapsScreen({super.key});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  static const sourceLocation = LatLng(25.836802982448937, 88.13001550734043);
  static const destinationLocation =
      LatLng(25.892098350735484, 88.25840931190439);
  late GoogleMapController _googleMapController;
  final locationController = Location();
  LatLng? currentPosition;
  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeMap();
  }

  Future<void> initializeMap() async {
    await fetchLocationUpdate();
    final coordinates = await fetchPolylinePoints();
    generatePolyLineFromPoints(coordinates);
    moveAnimateCameraPosition();
  }

  void moveAnimateCameraPosition() {
    _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: currentPosition!, zoom: 11)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Map'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),

      body: currentPosition == null
          ? const Center(
              child: Text('Loading...'),
            )
          : GoogleMap(
              initialCameraPosition:
                  const CameraPosition(target: sourceLocation, zoom: 11),
              mapType: MapType.terrain,
              markers: {
                Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: currentPosition!,
                    infoWindow: InfoWindow(
                        title: 'My Current Location',
                        snippet: currentPosition!.toString()),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRose)),
                Marker(
                    markerId: const MarkerId('sourceLocation'),
                    position: sourceLocation,
                    infoWindow: InfoWindow(
                        title: 'Source', snippet: sourceLocation.toString()),
                    icon: BitmapDescriptor.defaultMarker),
                Marker(
                    markerId: const MarkerId('destinationLocation'),
                    position: destinationLocation,
                    infoWindow: InfoWindow(
                        title: 'Destination',
                        snippet: destinationLocation.toString()),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange)),
              },
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (controller) => _googleMapController = controller,
            ),
    );
  }

  Future<void> fetchLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }
    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        currentPosition =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        setState(() {});
        print(currentPosition!);
      }
    });
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleMapApiKey,
      request: PolylineRequest(
        origin: PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        destination: PointLatLng(
            destinationLocation.latitude, destinationLocation.longitude),
        mode: TravelMode.driving,
      ),
    );
    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      debugPrint(result.errorMessage);
      return [];
    }
  }

  Future<void> generatePolyLineFromPoints(
      List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');
    final polyline = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates,
        width: 5);
    setState(() {
      polylines[id] = polyline;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _googleMapController.dispose();
  }
}
