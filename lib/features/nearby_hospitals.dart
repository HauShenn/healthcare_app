import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:healthcare_app/features/theme_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NearbyHospitalsPage extends StatefulWidget {
  @override
  _NearbyHospitalsPageState createState() => _NearbyHospitalsPageState();
}

class _NearbyHospitalsPageState extends State<NearbyHospitalsPage> {
  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getNearbyHospitals();
  }

  Future<void> _getNearbyHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final url = 'https://overpass-api.de/api/interpreter';
      final query = '''
    [out:json];
    (
      node["amenity"="hospital"](around:5000,${position.latitude},${position
          .longitude});
      way["amenity"="hospital"](around:5000,${position.latitude},${position
          .longitude});
      relation["amenity"="hospital"](around:5000,${position.latitude},${position
          .longitude});
    );
    out center;
    ''';

      final response = await http.post(Uri.parse(url), body: query);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _hospitals =
          List<Map<String, dynamic>>.from(data['elements'].map((hospital) {
            double lat = hospital['lat'] ?? hospital['center']['lat'];
            double lon = hospital['lon'] ?? hospital['center']['lon'];
            double distance = Geolocator.distanceBetween(
                position.latitude, position.longitude, lat, lon);
            return {
              "name": hospital['tags']['name'] ?? 'Unknown Hospital',
              "distance": (distance / 1000).toStringAsFixed(2), // Convert to km
            };
          }));
          _hospitals.sort((a, b) =>
              double.parse(a['distance']).compareTo(
                  double.parse(b['distance'])));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load hospitals');
      }
    } catch (e) {
      print('Error fetching hospitals: $e');
      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to find nearby hospitals. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ThemeConstants.mainGradient),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingWidget()
              : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildHospitalList(),
        ),
      ),
      floatingActionButton: Container(
        height: 70,
        width: 70,
        margin: EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: _getNearbyHospitals,
          backgroundColor: Colors.teal.shade600,
          child: Icon(Icons.refresh, size: ThemeConstants.iconLarge),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildHospitalList() {
    return ListView.builder(
      itemCount: _hospitals.length + 1, // +1 for the header
      padding: EdgeInsets.all(ThemeConstants.spacingLarge),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildListHeader();
        }
        final hospital = _hospitals[index - 1];
        return _buildHospitalCard(hospital);
      },
    );
  }

  Widget _buildListHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: ThemeConstants.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ThemeConstants.spacingSmall),
          Text(
            '${_hospitals.length} hospitals found near you',
            style: TextStyle(
              fontSize: ThemeConstants.bodySize,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> hospital) {
    return Container(
      margin: EdgeInsets.only(bottom: ThemeConstants.spacingLarge),
      decoration: ThemeConstants.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Hospital details action
          },
          child: Padding(
            padding: EdgeInsets.all(ThemeConstants.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        size: ThemeConstants.iconLarge,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    SizedBox(width: ThemeConstants.spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital['name'],
                            style: ThemeConstants.titleStyle,
                          ),
                          SizedBox(height: ThemeConstants.spacingSmall),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_walk,
                                color: Colors.grey.shade600,
                                size: ThemeConstants.iconSmall,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${hospital['distance']} km away',
                                style: ThemeConstants.bodyStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: CircularProgressIndicator(
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: ThemeConstants.spacingLarge),
          Text(
            'Finding nearby hospitals...',
            style: ThemeConstants.headerStyle.copyWith(
              fontSize: ThemeConstants.subtitleSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ThemeConstants.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red.shade100,
            ),
            SizedBox(height: ThemeConstants.spacingLarge),
            Text(
              _errorMessage,
              style: ThemeConstants.subtitleStyle.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeConstants.spacingLarge),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _getNearbyHospitals,
                icon: Icon(Icons.refresh, size: ThemeConstants.iconMedium),
                label: Text('Try Again'),
                style: ThemeConstants.primaryButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}