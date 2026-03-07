import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/listing_model.dart';
import '../models/user_profile_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Listings ─────────────────────────────────────────────────────────────

  Stream<List<ListingModel>> getAllListingsStream() {
    return _firestore
        .collection(AppConstants.listingsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  Stream<List<ListingModel>> getUserListingsStream(String uid) {
    return _firestore
        .collection(AppConstants.listingsCollection)
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs
          .map((doc) => ListingModel.fromFirestore(doc))
          .toList();
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }

  Future<String> addListing(ListingModel listing) async {
    final docRef = await _firestore
        .collection(AppConstants.listingsCollection)
        .add(listing.toMap());
    return docRef.id;
  }

  Future<void> updateListing(ListingModel listing) async {
    await _firestore
        .collection(AppConstants.listingsCollection)
        .doc(listing.id)
        .update(listing.toMap());
  }

  Future<void> deleteListing(String listingId) async {
    // Delete the listing and its reviews in a batch
    final batch = _firestore.batch();

    final listingRef = _firestore
        .collection(AppConstants.listingsCollection)
        .doc(listingId);
    batch.delete(listingRef);

    // Delete associated reviews
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('listingId', isEqualTo: listingId)
        .get();
    for (final doc in reviewsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ── User Profiles ─────────────────────────────────────────────────────────

  Future<void> createUserProfile(UserProfileModel profile) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(profile.uid)
        .set(profile.toMap());
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  Stream<UserProfileModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfileModel.fromFirestore(doc) : null);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  // ── Reviews ───────────────────────────────────────────────────────────────

  Stream<List<ReviewModel>> getReviewsStream(String listingId) {
    return _firestore
        .collection('reviews')
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  Future<void> addReview(ReviewModel review) async {
    final batch = _firestore.batch();

    // Add the review
    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, review.toMap());

    // Update the listing's rating stats
    final listingRef = _firestore
        .collection(AppConstants.listingsCollection)
        .doc(review.listingId);

    await batch.commit();

    // Recalculate average rating
    await _recalculateRating(review.listingId, listingRef);
  }

  Future<void> _recalculateRating(
      String listingId, DocumentReference listingRef) async {
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('listingId', isEqualTo: listingId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    final ratings =
        reviewsSnapshot.docs.map((doc) => (doc['rating'] as num).toDouble()).toList();
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;

    await listingRef.update({
      'averageRating': avg,
      'reviewCount': ratings.length,
    });
  }
}
