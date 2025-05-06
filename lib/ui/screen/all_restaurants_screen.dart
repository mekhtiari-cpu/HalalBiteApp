import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:halalbite_app/ui/screen/restaurant_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;

class AllRestaurantsScreen extends StatefulWidget {
  final List<dynamic> restaurants;
  final String googleApiKey;

  const AllRestaurantsScreen({
    super.key,
    required this.restaurants,
    required this.googleApiKey,
  });

  @override
  State<AllRestaurantsScreen> createState() => _AllRestaurantsScreenState();
}

class _AllRestaurantsScreenState extends State<AllRestaurantsScreen> {
  String _currentFilter = 'all';
  List<dynamic> _filteredRestaurants = [];
  final Map<String, bool> _spicyCache = {};
  final Map<String, bool> _vegCache = {};
  final Map<String, double> _distanceCache = {};
  Position? _currentPosition;
  bool _locationLoading = false;
  final List<double> _distanceFilters = [5, 10, 15, 20, 30, 40, 50];

  // Spicy detection parameters
  final List<String> _spicyKeywords = [
    'spicy', 'hot', 'chili', 'chilli', 'pepper', 'sichuan', 'szechuan',
    'thai', 'indian', 'mexican', 'sambal', 'harissa', 'curry', 'vindaloo',
    'phall', 'jalfrezi', 'piri piri', 'habanero', 'jalapeño', 'wasabi',
    'kimchi', 'gochujang', 'sriracha', 'tabasco', 'buffalo', 'cajun'
  ];

  final List<String> _spicyCuisines = [
    'indian', 'thai', 'sichuan', 'mexican', 'szechuan', 'hot_pot',
    'chinese', 'szechuan', 'korean', 'malaysian', 'indonesian',
    'ethiopian', 'sri_lankan', 'caribbean', 'laotian', 'vietnamese'
  ];

  final List<String> _vegKeywords = [
    'vegetarian', 'vegan', 'plant-based', 'meatless', 'plant based',
    'veg', 'meat-free', 'dairy-free', 'egg-free', 'tofu',
    'tempeh', 'seitan', 'falafel', 'hummus', 'salad bar',
    'greens', 'vegetable', 'veggie', 'lentil', 'bean',
    'gluten-free', 'organic', 'cruelty-free'
  ];

  final List<String> _vegCuisines = [
    'vegetarian', 'vegan', 'indian', 'mediterranean', 'middle_eastern',
    'thai', 'italian', 'greek', 'lebanese', 'israeli',
    'south_indian', 'ayurvedic', 'raw_food', 'health_food', 'vegetarian_friendly'
  ];

  @override
  void initState() {
    super.initState();
    _filteredRestaurants = widget.restaurants;
    _getCurrentLocation();
  }

  // Widget _buildFilterChip(String label, String filterValue, IconData? icon) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //     child: FilterChip(
  //       label: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           if (icon != null) ...[
  //             Icon(icon, size: 18),
  //             const SizedBox(width: 4),
  //           ],
  //           Text(label),
  //         ],
  //       ),
  //       selected: _currentFilter == filterValue,
  //       selectedColor: Colors.deepOrangeAccent,
  //       backgroundColor: Colors.grey[200],
  //       elevation: 4,
  //       checkmarkColor: Colors.white,
  //       labelStyle: TextStyle(
  //         color: _currentFilter == filterValue ? Colors.white : Colors.black,
  //       ),
  //       onSelected: (bool selected) {
  //         _applyFilter(selected ? filterValue : 'all');
  //       },
  //     ),
  //   );
  // }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationLoading = true;
    });

    try {
      final location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationLoading = false;
      });
      print('Current Location: $position');
    } catch (e) {
      setState(() {
        _locationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
  }

  Future<double> _getDistance(Map<String, dynamic> restaurant) async {
    final placeId = restaurant['place_id'];
    if (placeId != null && _distanceCache.containsKey(placeId)) {
      return _distanceCache[placeId]!;
    }

    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return double.infinity;
    }

    final lat = restaurant['geometry']['location']['lat'];
    final lng = restaurant['geometry']['location']['lng'];
    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
    final distanceInKm = distanceInMeters / 1000;

    if (placeId != null) {
      _distanceCache[placeId] = distanceInKm;
    }

    return distanceInKm;
  }

  Future<bool> _isSpicyRestaurant(Map<String, dynamic> restaurant) async {
    final placeId = restaurant['place_id'];
    if (placeId != null && _spicyCache.containsKey(placeId)) {
      return _spicyCache[placeId]!;
    }

    final name = restaurant['name']?.toString().toLowerCase() ?? '';
    if (_spicyKeywords.any((word) => name.contains(word))) {
      _spicyCache[placeId ?? ''] = true;
      return true;
    }

    final types = (restaurant['types'] as List?)?.cast<String>() ?? [];
    if (types.any((type) => _spicyCuisines.contains(type))) {
      _spicyCache[placeId ?? ''] = true;
      return true;
    }

    if (placeId != null) {
      final hasSpicyReviews = await _hasSpicyReviews(placeId);
      _spicyCache[placeId] = hasSpicyReviews;
      return hasSpicyReviews;
    }

    return false;
  }

  Future<bool> _hasSpicyReviews(String placeId) async {
    try {
      final reviewsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&fields=reviews'
            '&key=${widget.googleApiKey}',
      );

      final response = await http.get(reviewsUrl);
      final data = jsonDecode(response.body);
      final reviews = data['result']['reviews'] as List? ?? [];

      return reviews.any((review) {
        final text = review['text']?.toString().toLowerCase() ?? '';
        return _spicyKeywords.any((word) => text.contains(word));
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isVegetarianRestaurant(Map<String, dynamic> restaurant) async {
    final placeId = restaurant['place_id'];
    if (placeId != null && _vegCache.containsKey(placeId)) {
      return _vegCache[placeId]!;
    }

    final name = restaurant['name']?.toString().toLowerCase() ?? '';
    if (_vegKeywords.any((word) => name.contains(word))) {
      _vegCache[placeId ?? ''] = true;
      return true;
    }

    final types = (restaurant['types'] as List?)?.cast<String>() ?? [];
    if (types.any((type) => _vegCuisines.contains(type))) {
      _vegCache[placeId ?? ''] = true;
      return true;
    }

    if (placeId != null) {
      final hasVegReviews = await _hasVegetarianReviews(placeId);
      _vegCache[placeId] = hasVegReviews;
      return hasVegReviews;
    }

    return false;
  }

  Future<bool> _hasVegetarianReviews(String placeId) async {
    try {
      final reviewsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&fields=reviews'
            '&key=${widget.googleApiKey}',
      );

      final response = await http.get(reviewsUrl);
      final data = jsonDecode(response.body);
      final reviews = data['result']['reviews'] as List? ?? [];

      return reviews.any((review) {
        final text = review['text']?.toString().toLowerCase() ?? '';
        return _vegKeywords.any((word) => text.contains(word));
      });
    } catch (e) {
      return false;
    }
  }

  Future<void> _applyFilter(String filter) async {
    // Handle distance filters
    if (filter.startsWith('distance_')) {
      final distance = double.parse(filter.replaceAll('distance_', ''));

      setState(() {
        _currentFilter = filter;
        _filteredRestaurants = [];
      });

      final filteredRestaurants = <Map<String, dynamic>>[];
      for (final restaurant in widget.restaurants) {
        final restaurantDistance = await _getDistance(restaurant);
        if (restaurantDistance <= distance) {
          filteredRestaurants.add(restaurant);
        }
      }

      setState(() {
        _filteredRestaurants = filteredRestaurants;
      });
      return;
    }

    // Handle other filters
    if (filter != 'spicy' && filter != 'vegetarian' && filter != 'non_vegetarian') {
      setState(() {
        _currentFilter = filter;
        switch (filter) {
          case 'cheaper':
            _filteredRestaurants = widget.restaurants.where((r) =>
            (r['price_level'] == 1)
            ).toList();
            break;

          case 'middle':
            _filteredRestaurants = widget.restaurants.where((r) =>
            (r['price_level'] == 2)
            ).toList();
            break;

          case 'expensive':
            _filteredRestaurants = widget.restaurants.where((r) =>
            (r['price_level'] == 2 || r['price_level'] == 3)
            ).toList();
            break;

          case 'high_rating':
            _filteredRestaurants = widget.restaurants.where((r) =>
            (r['rating'] ?? 0) >= 4.5
            ).toList();
            break;
          default:
            _filteredRestaurants = widget.restaurants;
        }
      });
      return;
    }

    // Show loading indicator for special filters
    setState(() {
      _currentFilter = filter;
      _filteredRestaurants = [];
    });

    // Process filter asynchronously
    final filteredRestaurants = <Map<String, dynamic>>[];
    for (final restaurant in widget.restaurants) {
      if (filter == 'spicy') {
        if (await _isSpicyRestaurant(restaurant)) {
          filteredRestaurants.add(restaurant);
        }
      } else if (filter == 'vegetarian') {
        if (await _isVegetarianRestaurant(restaurant)) {
          filteredRestaurants.add(restaurant);
        }
      } else if (filter == 'non_vegetarian') {
        if (!(await _isVegetarianRestaurant(restaurant))) {
          filteredRestaurants.add(restaurant);
        }
      }
    }

    setState(() {
      _filteredRestaurants = filteredRestaurants;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('All Restaurants', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.search, color: Colors.black87),
          //   onPressed: () {
          //     // Implement search functionality
          //   },
          // ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.black87),
            onSelected: (String value) {
              if (value == 'clear') {
                _applyFilter('all');
              } else {
                _applyFilter('distance_$value');
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Text('Clear Filters'),
                ),
                const PopupMenuDivider(),
                ..._distanceFilters.map((distance) => PopupMenuItem<String>(
                  value: distance.toString(),
                  child: Text('Within ${distance.toInt()} km'),
                )),
              ];
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Enhanced filter chips
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildEnhancedFilterChip('All', 'all', null),
                      _buildEnhancedFilterChip('Spicy', 'spicy', Icons.local_fire_department),
                      _buildEnhancedFilterChip('Vegetarian', 'vegetarian', Icons.eco),
                      _buildEnhancedFilterChip('Non-Veg', 'non_vegetarian', Icons.fastfood),
                      _buildEnhancedFilterChip('Budget', 'cheaper', Icons.attach_money),
                      _buildEnhancedFilterChip('Top Rated', 'high_rating', Icons.star),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active filter indicator
          if (_currentFilter != 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentFilter.replaceAll('_', ' ').replaceAll('distance ', 'within ').replaceAll(RegExp(r'(\d+)$'), r'km'),
                          style: TextStyle(color: Colors.red[800], fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _applyFilter('all'),
                          child: Icon(Icons.close, size: 16, color: Colors.red[800]),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredRestaurants.length} results',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Loading indicator for special filters
          if (_locationLoading && _currentFilter.startsWith('distance_'))
            const LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)),

          // Restaurant list
          Expanded(
            child: (_filteredRestaurants.isEmpty &&
                (_currentFilter == 'spicy' ||
                    _currentFilter == 'vegetarian' ||
                    _currentFilter == 'non_vegetarian' ||
                    _currentFilter.startsWith('distance_')))
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding matching restaurants...'),
                ],
              ),
            )
                : _filteredRestaurants.isEmpty
                ? const Center(
              child: Text('No restaurants found for this filter'),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: _filteredRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _filteredRestaurants[index];
                return _buildEnhancedRestaurantCard(context, restaurant);
              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildEnhancedFilterChip(String label, String filterValue, IconData? icon) {
    final isSelected = _currentFilter == filterValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.red),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
        selected: isSelected,
        selectedColor: Colors.red,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        onSelected: (bool selected) {
          _applyFilter(selected ? filterValue : 'all');
        },
      ),
    );
  }

  Widget _buildEnhancedRestaurantCard(BuildContext context, Map<String, dynamic> restaurant) {
    final name = restaurant['name'];
    final address = restaurant['formatted_address'];
    final rating = restaurant['rating']?.toDouble() ?? 0.0;
    final photoRef = restaurant['photos']?[0]['photo_reference'];
    final imageUrl = photoRef != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoRef&key=${widget.googleApiKey}'
        : null;
    final lat = restaurant['geometry']['location']['lat'];
    final lng = restaurant['geometry']['location']['lng'];
    final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final priceLevel = restaurant['price_level']?.toInt() ?? 0;
    final isOpen = restaurant['opening_hours']?['open_now'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRestaurantDetails(context, restaurant, imageUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                        : Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpen ? 'OPEN NOW' : 'CLOSED',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FutureBuilder<double>(
                      future: _getDistance(restaurant),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${snapshot.data!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Restaurant info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (priceLevel > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '\$' * priceLevel,
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Rating and tags row
              Row(
                children: [
                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Spicy tag
                  FutureBuilder<bool>(
                    future: _isSpicyRestaurant(restaurant),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Spicy',
                                style: TextStyle(
                                    color: Colors.red[800],
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(width: 8),

                  // Vegetarian tag
                  FutureBuilder<bool>(
                    future: _isVegetarianRestaurant(restaurant),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Vegetarian',
                                style: TextStyle(
                                    color: Colors.green[800],
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.directions, size: 16),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: () => launchUrl(Uri.parse(mapUrl)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.language, size: 16),
                      label: const Text('Website'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: restaurant['website'] != null
                          ? () => launchUrl(Uri.parse(restaurant['website']))
                          : null,
                    ),
                  ),
                ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestaurantDetails(BuildContext context, Map<String, dynamic> restaurantData, String? imageUrl) {
    final placeId = restaurantData['place_id'];
    final detailsUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,rating,formatted_address,website,reviews,opening_hours,photos,formatted_phone_number,user_ratings_total,editorial_summary,geometry'
          '&key=${widget.googleApiKey}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FutureBuilder(
          future: http.get(detailsUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            final details = jsonDecode(snapshot.data!.body)['result'];
            final openingHours = (details['opening_hours']?['weekday_text'] as List?)?.join('\n') ?? 'Not available';
            final reviewsList = (details['reviews'] as List?) ?? [];
            final reviews = reviewsList.take(2).map((r) => {
              'text': r['text'] ?? '',
              'author_name': r['author_name'] ?? 'Anonymous',
              'profile_photo_url': r['profile_photo_url'] ?? '',
              'relative_time_description': r['relative_time_description'] ?? '',
              'rating': r['rating']?.toInt() ?? 0,
            }).toList();
            final reviewCount = details['user_ratings_total'] ?? 0;
            // String menuUrl = details['website'] ?? '';
            //
            // if (menuUrl.isEmpty || !menuUrl.contains("menu")) {
            //   menuUrl = '';
            // }
            final lat = details['geometry']['location']['lat'];
            final lng = details['geometry']['location']['lng'];
            final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
            final phone = details['formatted_phone_number'] ?? 'Not available';
            final photos = (details['photos'] as List?) ?? [];
            final menuPhotos = photos.take(10).map((p) {
              return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photo_reference=${p['photo_reference']}&key=${widget.googleApiKey}';
            }).toList();
            final description = details['editorial_summary']?['overview'] ??
                'A wonderful dining experience offering delicious cuisine in a welcoming atmosphere. '
                    'Known for its excellent service and quality ingredients.';

            return RestaurantDetailScreen(
              name: details['name'] ?? 'Unknown',
              imageUrl: imageUrl ?? '',
              rating: details['rating']?.toString() ?? 'N/A',
              reviewCount: reviewCount,
              address: details['formatted_address'] ?? 'N/A',
              website: details['website'] ?? 'N/A',
              openingHours: openingHours,
              reviews: reviews,
              menuPhotos: menuPhotos,
              phone: phone,
              description: description,
              mapUrl: mapUrl,
            );
          },
        ),
      ),
    );
  }
}