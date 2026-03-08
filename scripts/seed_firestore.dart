// ============================================================
// SEED SCRIPT — safe to delete after use
// ============================================================
// Run once with:
//   flutter run -t scripts/seed_firestore.dart
//
// The app will seed Firestore with sample Kigali listings,
// show a success/error status on screen, then you can stop it.
// Delete this file when done — it has zero effect on the project.
// ============================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kigali_locate/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SeedScreen(),
    );
  }
}

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  String _status = 'Ready to seed.';
  bool _seeding = false;
  bool _done = false;

  static final _listings = [
    {
      'name': 'King Faisal Hospital',
      'category': 'Hospital',
      'address': 'KG 544 St, Kacyiru, Kigali',
      'contactNumber': '+250 788 306 000',
      'description':
          'A leading referral hospital in Rwanda offering a wide range of specialist medical services.',
      'latitude': -1.9444,
      'longitude': 30.0619,
    },
    {
      'name': 'Kigali University Teaching Hospital (CHUK)',
      'category': 'Hospital',
      'address': 'KN 4 Ave, Nyarugenge, Kigali',
      'contactNumber': '+250 788 307 000',
      'description':
          'The main public teaching hospital in Kigali, providing comprehensive health services.',
      'latitude': -1.9508,
      'longitude': 30.0580,
    },
    {
      'name': 'Rwanda National Police HQ',
      'category': 'Police Station',
      'address': 'KN 4 Ave, Kimihurura, Kigali',
      'contactNumber': '+250 788 311 155',
      'description':
          'Headquarters of the Rwanda National Police. Emergency line: 112.',
      'latitude': -1.9380,
      'longitude': 30.0924,
    },
    {
      'name': 'Remera Police Station',
      'category': 'Police Station',
      'address': 'KG 11 Ave, Remera, Kigali',
      'contactNumber': '+250 788 311 100',
      'description': 'Local police station serving the Remera sector of Kigali.',
      'latitude': -1.9525,
      'longitude': 30.1132,
    },
    {
      'name': 'Inema Arts Center',
      'category': 'Tourist Attraction',
      'address': 'KG 14 Ave, Kacyiru, Kigali',
      'contactNumber': '+250 783 380 320',
      'description':
          'A vibrant art studio and gallery founded by two brothers, showcasing contemporary African art and hosting weekly events.',
      'latitude': -1.9378,
      'longitude': 30.0856,
    },
    {
      'name': 'Kigali Genocide Memorial',
      'category': 'Tourist Attraction',
      'address': 'Gasabo, Gisozi, Kigali',
      'contactNumber': '+250 252 501 014',
      'description':
          'A memorial and museum dedicated to the victims of the 1994 Genocide against the Tutsi.',
      'latitude': -1.9190,
      'longitude': 30.0604,
    },
    {
      'name': 'Nyandungu Eco Park',
      'category': 'Park',
      'address': 'Nyandungu, Kigali',
      'contactNumber': '+250 785 000 000',
      'description':
          'A restored urban wetland park with walking trails, bird watching, and green spaces.',
      'latitude': -1.9225,
      'longitude': 30.1128,
    },
    {
      'name': 'Gishushu Park',
      'category': 'Park',
      'address': 'Gishushu, Gasabo, Kigali',
      'contactNumber': '',
      'description':
          'A neighbourhood green park popular for morning jogs and family outings.',
      'latitude': -1.9410,
      'longitude': 30.0990,
    },
    {
      'name': 'Question Coffee',
      'category': 'Café',
      'address': 'KN 29 St, Kiyovu, Kigali',
      'contactNumber': '+250 788 609 360',
      'description':
          'A specialty coffee shop serving Rwandan single-origin brews. Proceeds support women coffee farmers.',
      'latitude': -1.9570,
      'longitude': 30.0600,
    },
    {
      'name': 'Bourbon Coffee Kimihurura',
      'category': 'Café',
      'address': 'KG 7 Ave, Kimihurura, Kigali',
      'contactNumber': '+250 252 501 345',
      'description':
          'Popular café chain with fast Wi-Fi, great Rwandan coffee, and light meals.',
      'latitude': -1.9352,
      'longitude': 30.0913,
    },
    {
      'name': 'Repub Lounge',
      'category': 'Restaurant',
      'address': 'KN 5 Rd, Kiyovu, Kigali',
      'contactNumber': '+250 788 386 800',
      'description':
          'Upscale restaurant and bar serving international cuisine with a rooftop view of Kigali.',
      'latitude': -1.9527,
      'longitude': 30.0561,
    },
    {
      'name': 'Nyamirambo Women\'s Center Restaurant',
      'category': 'Restaurant',
      'address': 'KN 47 St, Nyamirambo, Kigali',
      'contactNumber': '+250 788 386 844',
      'description':
          'Community restaurant run by a women\'s cooperative, serving authentic Rwandan dishes.',
      'latitude': -1.9737,
      'longitude': 30.0429,
    },
  ];

  Future<void> _seed() async {
    setState(() {
      _seeding = true;
      _status = 'Seeding listings...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('listings');

      for (int i = 0; i < _listings.length; i++) {
        final data = Map<String, dynamic>.from(_listings[i]);
        data['createdBy'] = 'seed_script';
        data['createdAt'] = Timestamp.now();
        data['averageRating'] = 0.0;
        data['reviewCount'] = 0;

        await collection.add(data);
        setState(() => _status = 'Added ${i + 1} / ${_listings.length}...');
      }

      setState(() {
        _status = 'Done! ${_listings.length} listings added.\nYou can close the app and delete this script.';
        _done = true;
        _seeding = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e\n\nMake sure your Firestore rules allow writes.';
        _seeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Firestore Seed Script',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: TextStyle(
                color: _done ? Colors.greenAccent : Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_done)
              ElevatedButton(
                onPressed: _seeding ? null : _seed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5C518),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _seeding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Seed ${12} Listings',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
