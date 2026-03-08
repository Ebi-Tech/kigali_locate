import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/listings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/category_chip_bar.dart';
import '../../widgets/empty_state.dart';
import 'listing_detail_screen.dart';
import 'add_edit_listing_screen.dart';
import 'package:geolocator/geolocator.dart';

final _userPositionProvider = FutureProvider<Position?>((ref) async {
  return LocationService().getCurrentLocation();
});

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredListingsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final positionAsync = ref.watch(_userPositionProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kigali City'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add Listing',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditListingScreen(),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          const SizedBox(height: 12),
          CategoryChipBar(
            selected: selectedCategory,
            onSelected: (cat) =>
                ref.read(selectedCategoryProvider.notifier).state = cat,
          ),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) =>
                  ref.read(searchQueryProvider.notifier).state = val,
            ),
          ),
          const SizedBox(height: 16),

          // Results label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  selectedCategory ?? AppStrings.allServices,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                filteredAsync.when(
                  data: (listings) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${listings.length}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Listings list
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Failed to load listings',
                subtitle: e.toString(),
              ),
              data: (listings) {
                if (listings.isEmpty) {
                  return EmptyState(
                    title: AppStrings.noResults,
                    subtitle: AppStrings.noResultsSubtitle,
                    action: user != null
                        ? ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditListingScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Listing'),
                          )
                        : null,
                  );
                }

                final position = positionAsync.value;

                return ListView.builder(
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    double? distance;
                    if (position != null) {
                      distance = Geolocator.distanceBetween(
                            position.latitude,
                            position.longitude,
                            listing.latitude,
                            listing.longitude,
                          ) /
                          1000;
                    }
                    return ListingCard(
                      listing: listing,
                      distanceKm: distance,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ListingDetailScreen(listing: listing),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
