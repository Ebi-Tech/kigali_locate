import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listings_provider.dart';
import '../../services/location_service.dart';

class AddEditListingScreen extends ConsumerStatefulWidget {
  final ListingModel? listing;

  const AddEditListingScreen({super.key, this.listing});

  @override
  ConsumerState<AddEditListingScreen> createState() =>
      _AddEditListingScreenState();
}

class _AddEditListingScreenState extends ConsumerState<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  String _selectedCategory = AppConstants.categories[1];
  bool _isFetchingLocation = false;

  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameController = TextEditingController(text: l?.name ?? '');
    _addressController = TextEditingController(text: l?.address ?? '');
    _contactController = TextEditingController(text: l?.contactNumber ?? '');
    _descriptionController = TextEditingController(text: l?.description ?? '');
    _latController =
        TextEditingController(text: l != null ? l.latitude.toString() : '');
    _lngController =
        TextEditingController(text: l != null ? l.longitude.toString() : '');
    if (l != null) _selectedCategory = l.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    final position = await LocationService().getCurrentLocation();
    setState(() => _isFetchingLocation = false);

    if (position != null) {
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not get location. Check permissions.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final lat = double.tryParse(_latController.text) ?? 0.0;
    final lng = double.tryParse(_lngController.text) ?? 0.0;

    final listing = ListingModel(
      id: widget.listing?.id ?? '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      address: _addressController.text.trim(),
      contactNumber: _contactController.text.trim(),
      description: _descriptionController.text.trim(),
      latitude: lat,
      longitude: lng,
      createdBy: user.uid,
      createdAt: widget.listing?.createdAt ?? DateTime.now(),
      averageRating: widget.listing?.averageRating ?? 0.0,
      reviewCount: widget.listing?.reviewCount ?? 0,
    );

    final notifier = ref.read(listingsNotifierProvider.notifier);
    final success = _isEditing
        ? await notifier.updateListing(listing)
        : await notifier.addListing(listing);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'Listing updated!' : 'Listing created!'),
          ),
        );
      } else {
        final error = ref.read(listingsNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error?.toString() ?? AppStrings.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(listingsNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editListing : AppStrings.addListing),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Service Name
            _fieldLabel('Service / Place Name'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Kimironko Café',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? AppStrings.errorRequired : null,
            ),
            const SizedBox(height: 20),

            // Category
            _fieldLabel('Category'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: BorderRadius.circular(12),
                  items: AppConstants.categories
                      .skip(1) // skip 'All'
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v ?? _selectedCategory),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Address
            _fieldLabel('Address'),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'e.g. KG 5 Ave, Kimironko, Kigali',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? AppStrings.errorRequired : null,
            ),
            const SizedBox(height: 20),

            // Contact Number
            _fieldLabel('Contact Number'),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. +250 788 000 000',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            _fieldLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the service or place...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.description_outlined),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? AppStrings.errorRequired : null,
            ),
            const SizedBox(height: 20),

            // Location
            Row(
              children: [
                _fieldLabel('Coordinates', flex: 0),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                  icon: _isFetchingLocation
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accent),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text(AppStrings.useCurrentLocation,
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '-1.9441',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.errorRequired;
                      }
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '30.0619',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppStrings.errorRequired;
                      }
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(_isEditing
                      ? AppStrings.saveChanges
                      : AppStrings.createListing),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, {int flex = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
