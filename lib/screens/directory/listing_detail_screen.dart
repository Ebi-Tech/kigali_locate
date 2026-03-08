import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/listing_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/star_rating.dart';
import 'add_edit_listing_screen.dart';
import 'package:uuid/uuid.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _userRating = 0;
  final _reviewController = TextEditingController();
  bool _showReviewForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _launchNavigation() async {
    final lat = widget.listing.latitude;
    final lng = widget.listing.longitude;
    final name = Uri.encodeComponent(widget.listing.name);

    // Try geo: URI first — opens the Maps app directly on device
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }

    // Fall back to Google Maps web URL
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps')),
      );
    }
  }

  Future<void> _callNumber() async {
    final number = widget.listing.contactNumber.trim();
    if (number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _submitReview() async {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).value;
    if (user == null) return;

    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    final review = ReviewModel(
      id: const Uuid().v4(),
      listingId: widget.listing.id,
      userId: user.uid,
      userName: profile?.fullName ?? user.displayName ?? 'Anonymous',
      rating: _userRating,
      comment: _reviewController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success =
        await ref.read(listingsNotifierProvider.notifier).addReview(review);
    if (mounted) {
      if (success) {
        setState(() {
          _showReviewForm = false;
          _userRating = 0;
          _reviewController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review.')),
        );
      }
    }
  }

  Future<void> _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteListing),
        content: const Text(AppStrings.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final success = await ref
        .read(listingsNotifierProvider.notifier)
        .deleteListing(widget.listing.id);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isOwner = user?.uid == widget.listing.createdBy;
    final reviewsAsync = ref.watch(reviewsProvider(widget.listing.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddEditListingScreen(listing: widget.listing),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  onPressed: _deleteListing,
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.cardBackground,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _categoryEmoji(widget.listing.category),
                      style: const TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.listing.category,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.listing.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.listing.category,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StarRatingDisplay(
                    rating: widget.listing.averageRating,
                    reviewCount: widget.listing.reviewCount,
                    size: 18,
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.location_on_outlined, widget.listing.address),
                  if (widget.listing.contactNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _callNumber,
                      child: _infoRow(Icons.phone_outlined,
                          widget.listing.contactNumber,
                          color: AppColors.accent),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    widget.listing.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchNavigation,
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text(AppStrings.getDirections),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _showReviewForm = !_showReviewForm),
                          icon:
                              const Icon(Icons.star_outline_rounded, size: 18),
                          label: const Text('Rate'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: AppColors.accent),
                            foregroundColor: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showReviewForm) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('Rate this service',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Center(
                      child: InteractiveStarRating(
                        initialRating: _userRating,
                        onRatingUpdate: (r) => setState(() => _userRating = r),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Share your experience (optional)...'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: user != null ? _submitReview : null,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44)),
                      child: const Text('Submit Review'),
                    ),
                    if (user == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Log in to submit a review.',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 12),
                            textAlign: TextAlign.center),
                      ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accent,
                    tabs: const [
                      Tab(text: 'Location'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMap(),
                        _buildReviews(reviewsAsync),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color ?? AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: color ?? AppColors.textSecondary, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final point = LatLng(widget.listing.latitude, widget.listing.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: AppConstants.detailZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.kigali.kigali_locate',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.location_pin,
                  color: AppColors.accent,
                  size: 48,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(AsyncValue<List<ReviewModel>> reviewsAsync) {
    return reviewsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.textHint))),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Text('No reviews yet.\nBe the first to review!',
                style: TextStyle(color: AppColors.textHint),
                textAlign: TextAlign.center),
          );
        }
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => _ReviewTile(review: reviews[i]),
        );
      },
    );
  }

  String _categoryEmoji(String category) {
    const map = {
      'Hospital': '🏥', 'Police Station': '👮', 'Library': '📚',
      'Restaurant': '🍽️', 'Café': '☕', 'Park': '🌳',
      'Tourist Attraction': '🏛️', 'Pharmacy': '💊', 'Bank': '🏦',
      'Hotel': '🏨', 'School': '🏫',
    };
    return map[category] ?? '📍';
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.inputBackground,
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    StarRatingDisplay(
                        rating: review.rating, size: 12, showCount: false),
                  ],
                ),
              ),
              Text(_timeAgo(review.createdAt),
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11)),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${review.comment}"',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
