import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/empty_state.dart';
import '../auth/login_screen.dart';
import '../directory/add_edit_listing_screen.dart';
import '../directory/listing_detail_screen.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.myListings)),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in required',
          subtitle: 'Log in to manage your listings.',
          action: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text(AppStrings.login),
          ),
        ),
      );
    }

    final myListingsAsync = ref.watch(myListingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myListings),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Listing',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditListingScreen()),
            ),
          ),
        ],
      ),
      body: myListingsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load',
          subtitle: e.toString(),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return EmptyState(
              icon: Icons.add_location_alt_outlined,
              title: 'No listings yet',
              subtitle: 'Add your first service or place listing.',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddEditListingScreen()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(AppStrings.addListing),
              ),
            );
          }

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Dismissible(
                key: Key(listing.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
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
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await ref
                      .read(listingsNotifierProvider.notifier)
                      .deleteListing(listing.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing deleted.')),
                    );
                  }
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.error.withValues(alpha: 0.15),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
                child: Stack(
                  children: [
                    ListingCard(
                      listing: listing,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ListingDetailScreen(listing: listing),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 36,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditListingScreen(listing: listing),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.accent,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
