class AppConstants {
  // Firestore Collections
  static const String listingsCollection = 'listings';
  static const String usersCollection = 'users';

  // Categories
  static const List<String> categories = [
    'All',
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
    'Pharmacy',
    'Bank',
    'Hotel',
    'School',
  ];

  static const List<String> categoryIcons = [
    '🏢', // All
    '🏥', // Hospital
    '👮', // Police Station
    '📚', // Library
    '🍽️', // Restaurant
    '☕', // Café
    '🌳', // Park
    '🏛️', // Tourist Attraction
    '💊', // Pharmacy
    '🏦', // Bank
    '🏨', // Hotel
    '🏫', // School
  ];

  // Kigali center coordinates
  static const double kigaliLat = -1.9441;
  static const double kigaliLng = 30.0619;

  // Map defaults
  static const double defaultZoom = 13.0;
  static const double detailZoom = 16.0;
}

class AppStrings {
  static const String appName = 'Kigali Locate';
  static const String tagline = 'Discover Kigali City';

  // Auth
  static const String login = 'Log In';
  static const String signup = 'Sign Up';
  static const String logout = 'Log Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account? ";
  static const String hasAccount = 'Already have an account? ';
  static const String verifyEmailTitle = 'Verify Your Email';
  static const String verifyEmailBody =
      'A verification link has been sent to your email address. Please verify your email to continue.';
  static const String resendEmail = 'Resend Email';
  static const String checkVerification = 'I\'ve Verified';

  // Directory
  static const String directory = 'Directory';
  static const String searchHint = 'Search for a service...';
  static const String nearYou = 'Near You';
  static const String allServices = 'All Services';
  static const String noResults = 'No services found';
  static const String noResultsSubtitle = 'Try adjusting your search or category filter';

  // Listings
  static const String myListings = 'My Listings';
  static const String addListing = 'Add Listing';
  static const String editListing = 'Edit Listing';
  static const String deleteListing = 'Delete Listing';
  static const String deleteConfirm = 'Are you sure you want to delete this listing?';
  static const String serviceName = 'Service / Place Name';
  static const String category = 'Category';
  static const String address = 'Address';
  static const String contactNumber = 'Contact Number';
  static const String description = 'Description';
  static const String latitude = 'Latitude';
  static const String longitude = 'Longitude';
  static const String useCurrentLocation = 'Use My Current Location';
  static const String saveChanges = 'Save Changes';
  static const String createListing = 'Create Listing';

  // Map
  static const String mapView = 'Map View';
  static const String getDirections = 'Get Directions';
  static const String openInMaps = 'Open in Maps';

  // Settings
  static const String settings = 'Settings';
  static const String profile = 'Profile';
  static const String notifications = 'Location Notifications';
  static const String notificationsSubtitle =
      'Get notified about services near your location';
  static const String editProfile = 'Edit Profile';

  // Errors
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorEmail = 'Please enter a valid email address.';
  static const String errorPassword = 'Password must be at least 6 characters.';
  static const String errorPasswordMatch = 'Passwords do not match.';
  static const String errorName = 'Please enter your full name.';
  static const String errorRequired = 'This field is required.';
}
