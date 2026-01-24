import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/nearby_lawyers_controller.dart';
import '../models/nearby_lawyer_model.dart';
import '../../calling_booking/models/consultant_models.dart' as calling;

class LawyersMapScreen extends StatefulWidget {
  const LawyersMapScreen({super.key});

  @override
  State<LawyersMapScreen> createState() => _LawyersMapScreenState();
}

class _LawyersMapScreenState extends State<LawyersMapScreen> {
  final MapController _mapController = MapController();
  final controller = Get.find<NearbyLawyersController>();
  NearbyLawyer? _selectedLawyer;

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add user location marker
    if (controller.userLocation != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(
            controller.userLocation!.latitude,
            controller.userLocation!.longitude,
          ),
          child: Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }

    // Add lawyer markers
    for (var lawyer in controller.lawyers) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(lawyer.location.latitude, lawyer.location.longitude),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLawyer = lawyer;
              });
            },
            child: Icon(
              Icons.location_on,
              color: _getMarkerColor(lawyer.consultantType),
              size: 40,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Color _getMarkerColor(String? userType) {
    switch (userType) {
      case 'advocate':
        return Colors.orange;
      case 'lawyer':
        return Colors.amber;
      case 'paralegal':
        return Colors.green;
      case 'law_firm':
        return Colors.red;
      default:
        return Colors.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userLocation = controller.userLocation;

    if (userLocation == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Map View')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3)),
              SizedBox(height: 16),
              Text('Location not available'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map (Leaflet)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  LatLng(userLocation.latitude, userLocation.longitude),
              initialZoom: 13,
              onTap: (_, __) {
                // Hide bottom sheet when tapping map
                setState(() {
                  _selectedLawyer = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pola',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // Top bar with back button
          SafeArea(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      '${controller.count} Lawyers Nearby',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.radius}km',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My location button
          Positioned(
            right: 16,
            bottom: _selectedLawyer != null ? 220 : 100,
            child: FloatingActionButton(
              heroTag: 'my_location_button',
              mini: true,
              backgroundColor: theme.colorScheme.surface,
              onPressed: _goToUserLocation,
              child: Icon(Icons.my_location, color: theme.colorScheme.primary),
              elevation: 2,
            ),
          ),

          // List view toggle button
          Positioned(
            left: 16,
            bottom: _selectedLawyer != null ? 220 : 100,
            child: FloatingActionButton.extended(
              heroTag: 'list_toggle_button',
              backgroundColor: theme.colorScheme.surface,
              onPressed: () => Get.back(),
              icon: Icon(Icons.list,
                  color: theme.colorScheme.onSurface, size: 20),
              label: Text(
                'List',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              elevation: 2,
            ),
          ),

          // Bottom sheet for selected lawyer
          if (_selectedLawyer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildLawyerBottomSheet(context, _selectedLawyer!),
            ),
        ],
      ),
    );
  }

  Widget _buildLawyerBottomSheet(BuildContext context, NearbyLawyer lawyer) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - tappable to view full profile
                  InkWell(
                    onTap: () {
                      final consultant = _convertToConsultant(lawyer);
                      Get.toNamed('/consultant-detail',
                          arguments: {'consultant': consultant});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: lawyer.profilePicture != null
                                ? NetworkImage(lawyer.profilePicture!)
                                : null,
                            child: lawyer.profilePicture == null
                                ? Text(
                                    lawyer.getUserTypeIcon(),
                                    style: TextStyle(fontSize: 24),
                                  )
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lawyer.name ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lawyer.getUserTypeLabel(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.navigation,
                                        size: 14, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text(
                                      '${lawyer.distanceKm.toStringAsFixed(1)}km',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedLawyer = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Specialization
                  if (lawyer.specialization != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lawyer.specialization!,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],

                  SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      // Call button - only show if mobile consultations offered
                      if (lawyer.offersMobileConsultations)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _callLawyer(lawyer),
                            icon: Icon(Icons.phone, size: 16),
                            label: Text('Call', style: TextStyle(fontSize: 14)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side:
                                  BorderSide(color: theme.colorScheme.outline),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (lawyer.offersMobileConsultations &&
                          lawyer.offersPhysicalConsultations &&
                          lawyer.consultantType.toLowerCase() == 'law_firm')
                        SizedBox(width: 10),
                      // Book button - only show for LAW FIRMS that offer physical consultations
                      if (lawyer.offersPhysicalConsultations &&
                          lawyer.consultantType.toLowerCase() == 'law_firm')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _bookConsultation(lawyer),
                            icon: Icon(Icons.calendar_today, size: 16),
                            label: Text('Book', style: TextStyle(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                      if (lawyer.offersMobileConsultations ||
                          (lawyer.offersPhysicalConsultations &&
                              lawyer.consultantType.toLowerCase() == 'law_firm'))
                        SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _openInMaps(lawyer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          elevation: 0,
                        ),
                        child: Icon(Icons.directions, size: 18),
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

  void _goToUserLocation() {
    if (controller.userLocation != null) {
      _mapController.move(
        LatLng(
          controller.userLocation!.latitude,
          controller.userLocation!.longitude,
        ),
        14,
      );
    }
  }

  void _callLawyer(NearbyLawyer lawyer) async {
    final consultant = _convertToConsultant(lawyer);
    Get.toNamed('/call', arguments: {'consultant': consultant});
  }

  calling.Consultant _convertToConsultant(NearbyLawyer lawyer) {
    return calling.Consultant(
      id: lawyer.id,
      userDetails: calling.UserDetails(
        id: lawyer.userDetails.id,
        email: lawyer.userDetails.email ?? '',
        firstName: lawyer.userDetails.firstName ?? '',
        lastName: lawyer.userDetails.lastName ?? '',
        fullName: lawyer.userDetails.fullName ?? '',
        phoneNumber: lawyer.userDetails.phoneNumber,
        profilePicture: lawyer.userDetails.profilePicture,
      ),
      consultantType: lawyer.consultantType,
      specialization: lawyer.specialization ?? '',
      yearsOfExperience: lawyer.yearsOfExperience ?? 0,
      offersMobileConsultations: lawyer.offersMobileConsultations,
      offersPhysicalConsultations: lawyer.offersPhysicalConsultations,
      city: lawyer.city,
      isAvailable: lawyer.isAvailable,
      totalConsultations: lawyer.totalConsultations,
      totalEarnings: lawyer.totalEarnings,
      averageRating: lawyer.averageRating ?? 0.0,
      totalReviews: lawyer.totalReviews,
      pricing: calling.ConsultantPricing(
        mobile: calling.PricingDetails(
          price: lawyer.pricing.mobile.price.toString(),
          consultantShare: lawyer.pricing.mobile.consultantShare.toString(),
          platformShare: lawyer.pricing.mobile.platformShare.toString(),
        ),
      ),
      isOnline: lawyer.isOnline,
    );
  }

  void _bookConsultation(NearbyLawyer lawyer) {
    final consultant = _convertToConsultant(lawyer);
    // Book button is for physical consultations
    Get.toNamed('/book-consultation', arguments: {
      'consultant': consultant,
      'bookingType': 'physical',
    });
  }

  void _openInMaps(NearbyLawyer lawyer) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${lawyer.location.latitude},${lawyer.location.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
