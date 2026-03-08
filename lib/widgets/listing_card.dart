import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/listing_model.dart';
import 'star_rating.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final double? distanceKm;
  final bool compact;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.distanceKm,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 14,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Category icon circle
            Container(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Center(
                child: Text(
                  _getCategoryEmoji(listing.category),
                  style: TextStyle(fontSize: compact ? 18 : 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Rating + distance column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StarRatingDisplay(
                  rating: listing.averageRating,
                  reviewCount: listing.reviewCount,
                  size: 14,
                ),
                if (distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDistance(distanceKm!),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1.0) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Hospital':
        return '🏥';
      case 'Police Station':
        return '👮';
      case 'Library':
        return '📚';
      case 'Restaurant':
        return '🍽️';
      case 'Café':
        return '☕';
      case 'Park':
        return '🌳';
      case 'Tourist Attraction':
        return '🏛️';
      case 'Pharmacy':
        return '💊';
      case 'Bank':
        return '🏦';
      case 'Hotel':
        return '🏨';
      case 'School':
        return '🏫';
      default:
        return '📍';
    }
  }
}
