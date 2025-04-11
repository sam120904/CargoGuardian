import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dashboard_page.dart';
import 'connection_indicator.dart';

class LocationTab extends StatelessWidget {
  final Size screenSize;
  final DashboardData data;
  final DashboardCallbacks callbacks;
  
  // Train location coordinates
  final LatLng _trainLocation = const LatLng(28.6139, 77.2090); // Delhi coordinates
  
  const LocationTab({
    super.key,
    required this.screenSize,
    required this.data,
    required this.callbacks,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            // Error message if any
            if (data.errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.errorMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Location permission request if needed
            if (!data.hasLocationPermission && !data.isRequestingPermission)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_off,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Location permission is required to show the map',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.location_on),
                      label: const Text('Grant Location Permission'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onPressed: callbacks.requestLocationPermission,
                    ),
                  ],
                ),
              ),
            
            // Show loading indicator while requesting permission
            if (data.isRequestingPermission)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Requesting location permission...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            
            // GPS Location Map - Using a different approach for web vs mobile
            Container(
              height: 400, // Fixed height for the map
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: data.connectionStatus == ConnectionStatus.disconnected
                  ? _buildOfflineMapPlaceholder()
                  : data.hasLocationPermission
                    ? kIsWeb
                      // For web, show a placeholder with instructions
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 64,
                                color: Colors.blue.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Map View',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Location: Delhi Central Station (${_trainLocation.latitude}, ${_trainLocation.longitude})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open in Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                ),
                                onPressed: () {
                                  // Open Google Maps in a new tab using our platform-safe method
                                  callbacks.openUrl('https://www.google.com/maps/search/?api=1&query=${_trainLocation.latitude},${_trainLocation.longitude}');
                                },
                              ),
                            ],
                          ),
                        )
                      // For mobile, use the GoogleMap widget
                      : _buildGoogleMap()
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Map unavailable',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please grant location permission to view the map',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Location Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLocationDetail(
                        Icons.speed, 
                        'Speed', 
                        data.connectionStatus == ConnectionStatus.disconnected ? '0 km/h' : '45 km/h',
                        data.connectionStatus == ConnectionStatus.disconnected,
                      ),
                      _buildLocationDetail(
                        Icons.navigation, 
                        'Direction', 
                        data.connectionStatus == ConnectionStatus.disconnected ? 'N/A' : 'North',
                        data.connectionStatus == ConnectionStatus.disconnected,
                      ),
                      _buildLocationDetail(
                        Icons.timer, 
                        'ETA', 
                        data.connectionStatus == ConnectionStatus.disconnected ? 'N/A' : '2h 15m',
                        data.connectionStatus == ConnectionStatus.disconnected,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: data.connectionStatus == ConnectionStatus.disconnected 
                          ? Colors.grey.shade500 
                          : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.connectionStatus == ConnectionStatus.disconnected 
                            ? 'Current: Unknown' 
                            : 'Current: Delhi Central Station',
                          style: TextStyle(
                            fontSize: 14,
                            color: data.connectionStatus == ConnectionStatus.disconnected 
                              ? Colors.grey.shade500 
                              : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 20,
                        color: data.connectionStatus == ConnectionStatus.disconnected 
                          ? Colors.grey.shade500 
                          : Colors.green.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.connectionStatus == ConnectionStatus.disconnected 
                            ? 'Destination: Unknown' 
                            : 'Destination: Mumbai Central',
                          style: TextStyle(
                            fontSize: 14,
                            color: data.connectionStatus == ConnectionStatus.disconnected 
                              ? Colors.grey.shade500 
                              : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOfflineMapPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'IoT device is offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Location data unavailable',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoogleMap() {
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _trainLocation,
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('train'),
            position: _trainLocation,
            infoWindow: InfoWindow(
              title: data.selectedTrain,
              snippet: 'Speed: 45 km/h, Direction: North',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        },
        myLocationEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
      );
    } catch (e) {
      print('Error creating Google Map: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your Google Maps API key',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildLocationDetail(IconData icon, String label, String value, bool isOffline) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
          color: isOffline ? Colors.grey.shade500 : Colors.blue.shade700,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isOffline ? Colors.grey.shade500 : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
