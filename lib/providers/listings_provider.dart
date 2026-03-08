import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';
import 'auth_provider.dart';

// ── Search & Filter State ─────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ── Listings Streams ──────────────────────────────────────────────────────

final allListingsStreamProvider = StreamProvider<List<ListingModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllListingsStream();
});

final myListingsStreamProvider = StreamProvider<List<ListingModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getUserListingsStream(user.uid);
});

// ── Filtered Listings (computed) ──────────────────────────────────────────

final filteredListingsProvider = Provider<AsyncValue<List<ListingModel>>>((ref) {
  final listingsAsync = ref.watch(allListingsStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final category = ref.watch(selectedCategoryProvider);

  return listingsAsync.when(
    data: (listings) {
      var filtered = listings;

      if (query.isNotEmpty) {
        filtered = filtered
            .where((l) =>
                l.name.toLowerCase().contains(query) ||
                l.address.toLowerCase().contains(query) ||
                l.description.toLowerCase().contains(query))
            .toList();
      }

      if (category != null && category != 'All') {
        filtered = filtered.where((l) => l.category == category).toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// ── Reviews Stream ────────────────────────────────────────────────────────

final reviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, listingId) {
  return ref.watch(firestoreServiceProvider).getReviewsStream(listingId);
});

// ── Listings Notifier (CRUD actions) ─────────────────────────────────────

class ListingsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;

  ListingsNotifier(this._firestoreService)
      : super(const AsyncValue.data(null));

  Future<bool> addListing(ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.addListing(listing);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> updateListing(ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateListing(listing);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> deleteListing(String listingId) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteListing(listingId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> addReview(ReviewModel review) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.addReview(review);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

final listingsNotifierProvider =
    StateNotifierProvider<ListingsNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return ListingsNotifier(firestoreService);
});
