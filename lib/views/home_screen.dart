import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_tracking/shared/constants/constants.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  static const String route = "HomeScreen";
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final Completer<GoogleMapController> _mapcontroller = Completer();
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  static const LatLng sourceLocation = LatLng(30.0509167, 30.97047222222222);
  static const LatLng destination = LatLng(30.046839, 30.968750);
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(
          size: Size(20, 20),

        ), "assets/images/motorcycle2.png")
        .then(
          (icon) {
        currentLocationIcon = icon;
      },
    );
  }
  void getPolyPoints() async {
   /* List<LatLng> test = polylinePoints.decodePolyline("cjlvDm|_|D@mE?}H@qKCgBCIGKCsBLeAPCd@KtE?`DBlB@fEFLJJTD\\AtB@~BIzD?pCrBFjAJXJRLNVBLDt@CdRKbPSb@_@XyBAYCSKEES_@EW@uC@_E").map((e) => LatLng(e.latitude, e.longitude)).toList();
    test.forEach((element) {print("${element.longitude} - ${element.latitude}"); });*/
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Platform.isIOS?Constants.iosGoogleMapApiKey:Constants.androidGoogleMapApiKey, // Your Google Map Key
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );
    if (result.points.isNotEmpty) {
      result.points.forEach(
            (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {});
    }
  }

  Position? currentLocation;
  void getMyLocation()async{
    print("get location");
    bool isServiceEnabled;
    LocationPermission permission;
    Location location = Location();
    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!isServiceEnabled){
      bool isturnedon = await location.requestService();
      if(!isturnedon){
        print("Location service disable");
        return ;
      }
    }
    print("Location service enable");
    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      print("Location denied2");
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location denied1");
        return;
      }
    }
    if(permission == LocationPermission.deniedForever){
      print("Location deniedfor");
      return ;
    }
    currentLocation = await Geolocator.getCurrentPosition();
    setState(() {

    });
    GoogleMapController newController = await _mapcontroller.future;

    Geolocator.getPositionStream().listen((newPosition) {
      currentLocation = newPosition;
      print("new latlng : ${currentLocation?.latitude} - ${currentLocation?.longitude}");
      newController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(newPosition.latitude, newPosition.longitude),
            zoom: 13.5
        )
      ));
      setState(() {

      });
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMyLocation();
    getPolyPoints();
    setCustomMarkerIcon();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation==null
          ?const Center(child: Text("Loading...",style: TextStyle(color: Colors.black,fontSize: 20),),)
          :GoogleMap(
        onMapCreated: (controller){
          _mapcontroller.complete(controller);
        },
          initialCameraPosition: const CameraPosition(
            target: sourceLocation,
            zoom: 13.5,
          ),
        polylines:{
            Polyline(
              polylineId: const PolylineId("route"),
              width: 6,
              color: Colors.blueGrey,
              points: polylineCoordinates
            )
        },
        markers: {
          Marker(
            icon: currentLocationIcon,
            markerId: MarkerId("current"),
            position: LatLng(currentLocation!.latitude, currentLocation!.longitude),
          ),
          const Marker(

            markerId: MarkerId("source"),
            position: sourceLocation,
          ),
          const Marker(
            markerId: MarkerId("destination"),
            position: destination,
          ),
        },

      )
      ,
    );
  }
}
