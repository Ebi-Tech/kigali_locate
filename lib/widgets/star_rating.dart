import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../core/app_theme.dart';

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;
  final bool showCount;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, _) => const Icon(
            Icons.star_rounded,
            color: AppColors.accent,
          ),
          itemCount: 5,
          itemSize: size,
          unratedColor: AppColors.textHint,
        ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '0.0',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (reviewCount > 0) ...[
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: size * 0.75,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class InteractiveStarRating extends StatelessWidget {
  final double initialRating;
  final ValueChanged<double> onRatingUpdate;
  final double size;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingUpdate,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: size,
      itemBuilder: (context, _) => const Icon(
        Icons.star_rounded,
        color: AppColors.accent,
      ),
      unratedColor: AppColors.textHint,
      onRatingUpdate: onRatingUpdate,
    );
  }
}
