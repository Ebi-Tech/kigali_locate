import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/listing_model.dart';
import '../../providers/listings_provider.dart';
import '../directory/listing_detail_screen.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  String? _selectedCategory;
  final _mapController = MapController();

  static const _kigali =
      LatLng(AppConstants.kigaliLat, AppConstants.kigaliLng);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((listing) {
      final color = _categoryColor(listing.category);
      return Marker(
        point: LatLng(listing.latitude, listing.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ListingDetailScreen(listing: listing)),
          ),
          child: Tooltip(
            message: listing.name,
            child: Icon(Icons.location_pin, color: color, size: 44),
          ),
        ),
      );
    }).toList();
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Hospital':       return Colors.red;
      case 'Police Station': return Colors.blue;
      case 'Park':           return Colors.green;
      case 'Café':
      case 'Restaurant':     return Colors.orange;
      case 'Tourist Attraction': return Colors.purple;
      case 'Pharmacy':       return Colors.cyan;
      default:               return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(allListingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mapView)),
      body: Stack(
        children: [
          listingsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.textHint))),
            data: (allListings) {
              final filtered = _selectedCategory == null
                  ? allListings
                  : allListings
                      .where((l) => l.category == _selectedCategory)
                      .toList();

              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _kigali,
                  initialZoom: AppConstants.defaultZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kigali.kigali_locate',
                  ),
                  MarkerLayer(markers: _buildMarkers(filtered)),
                ],
              );
            },
          ),

          // Category filter strip
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _filterChip('All', null),
                  ...AppConstants.categories.skip(1).map(
                        (c) => _filterChip(c, c),
                      ),
                ],
              ),
            ),
          ),

          // Count badge at bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: listingsAsync.maybeWhen(
              data: (listings) {
                final count = _selectedCategory == null
                    ? listings.length
                    : listings
                        .where((l) => l.category == _selectedCategory)
                        .length;
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$count location${count == 1 ? 's' : 's'} on map',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
