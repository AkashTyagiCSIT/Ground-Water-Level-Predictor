import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/const/urls.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../provider/map_provider/circle_outline_map_provider.dart';
import 'package:http/http.dart' as http;

import '../provider/map_provider/location_provider.dart';
import '../utils/calculate_distance.dart';


class FullScreenMap extends StatefulWidget {
  const FullScreenMap({super.key});

  @override
  State<FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(27.1767, 78.0081),
    zoom: 10,
  );


  final TextEditingController _searchController = TextEditingController();
  var uuid = Uuid();
  String _SessionToken=  '112233';

  List<dynamic> _placesList= [];
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener((){
      onChange();
    });
    _addStationMarkers();
  }

  void onChange(){
    if(_SessionToken.isEmpty){
      setState(() {
        _SessionToken=uuid.v4();
      });
    }
    getSuggestion(_searchController.text);
  }

  void _addStationMarkers() {
    for (var station in stations) {
      _markers.add(
        Marker(
          markerId: MarkerId(station['id'].toString()),
          position: LatLng(
            station['latitude'] is int
                ? (station['latitude'] as int).toDouble()
                : station['latitude'],
            station['longitude'] is int
                ? (station['longitude'] as int).toDouble()
                : station['longitude'],
          ),
          infoWindow: InfoWindow(
            title: station['name'],
            snippet: "ID: ${station['id']}",
          ),
        ),
      );
    }
  }

  Future<void> _handleSearch(String query, MapState mapState) async {
    if (query.trim().isEmpty) return;

    final normalizedQuery = query.trim().toUpperCase();

    // 1. Search locally in our Agra stations list
    Map<String, dynamic>? matchedStation;
    for (var station in stations) {
      if (station['name'].toString().toUpperCase() == normalizedQuery ||
          station['id'].toString() == normalizedQuery) {
        matchedStation = station;
        break;
      }
    }

    if (matchedStation != null) {
      final latitude = matchedStation['latitude'] is int
          ? (matchedStation['latitude'] as int).toDouble()
          : matchedStation['latitude'] as double;

      final longitude = matchedStation['longitude'] is int
          ? (matchedStation['longitude'] as int).toDouble()
          : matchedStation['longitude'] as double;

      final position = LatLng(latitude, longitude);

      final controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 14),
      ));

      mapState.updateCircle(position);
      Provider.of<LocationState>(context, listen: false).updateSelectedLocation(position);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Found station: ${matchedStation['name']}")),
      );
      return;
    }

    // 2. Fallback to address geocoding
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final position = LatLng(loc.latitude, loc.longitude);

        final controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 12),
        ));

        mapState.updateCircle(position);
        Provider.of<LocationState>(context, listen: false).updateSelectedLocation(position);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Address found!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Station or Location not found")),
      );
    }
  }

  void getSuggestion(String input) async{

    String GOOGLE_MAPS_API_KEY= AppConstants.googleMapsApiKey;
    String baseURL =AppConstants.baseUrl;

    String request = '$baseURL?input=$input&key=$GOOGLE_MAPS_API_KEY&sessiontoken=$_SessionToken';

    try {
      var response = await http.get(Uri.parse(request));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _placesList = jsonDecode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Consumer<MapState>(
              builder: (context, mapState, child) {
                return GoogleMap(
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  mapType: MapType.normal,
                  markers: _markers,
                  circles: mapState.circles,
                  onTap: (LatLng position) {

                    mapState.updateCircle(position);

                  },
                );
              },
            ),
            Consumer<MapState>(
              builder: (context, mapState, child) {
                return Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2), // Shadow position
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search location or Well ID (e.g. W15445)...',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onSubmitted: (value) => _handleSearch(value, mapState),
                    ),
                  ),
                );
              }
            ), //search bar

            if (_placesList != null && _placesList.isNotEmpty)
              Positioned(
                top: 70, // Adjust this to match the height of the search bar plus padding
                left: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // Semi-transparent background
                    borderRadius: BorderRadius.circular(10), // Optional rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true, // Prevent ListView from expanding infinitely
                    itemCount: _placesList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_placesList[index]['description']),
                        onTap: () async {
                          try {
                            List<Location> locations = await locationFromAddress(
                              _placesList[index]['description'],
                            );
                            if (locations.isNotEmpty) {
                              _searchController.text = _placesList[index]['description'];

                              Location selectedLocation = locations.first;

                              final GoogleMapController mapController = await _controller.future;
                              await mapController.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(selectedLocation.latitude, selectedLocation.longitude),
                                    zoom: 10,
                                  ),
                                ),
                              );

                              Provider.of<MapState>(context, listen: false).updateCircle(
                                LatLng(selectedLocation.latitude, selectedLocation.longitude),
                              );

                              Provider.of<LocationState>(context, listen: false).updateSelectedLocation(
                                LatLng(selectedLocation.latitude, selectedLocation.longitude),
                              );

                              setState(() {
                                _placesList.clear();
                                _searchController.clear();
                                _SessionToken = "";
                              });
                            }
                          } catch (e) {
                            print("Error handling suggestion tap: $e");
                          }
                        },

                      );
                    },
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              left: 10,
              child: FloatingActionButton(
                onPressed: () {

                  Navigator.pop(context);
                },
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.blueAccent,
                ),
                mini: true, // Smaller button size
              ),
            ),
          ],
        ),
      ),
    );
  }
}
