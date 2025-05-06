import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:halalbite_app/ui/screen/all_restaurants_screen.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import 'restaurant_detail_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  List<dynamic> _restaurants = [];
  bool _isLoadingRestaurants = false;
  bool _isSendingMessage = false;
  bool _showLocationPermissionBanner = false;

  final String openAiKey = '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';
  final String googleApiKey = 'AIzaSyAFDOTJ9l1y84lAG9G-iFxEJ5uDLBLUKM4';
  Position? _userPosition;
  String _lastQuery = '';

  // final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  // late CollectionReference _chatCollection;

  // Color scheme
  final Color primaryColor = const Color(0xFF4CAF50); // Green
  final Color accentColor = const Color(0xFF8BC34A); // Light Green
  final Color botMessageColor = const Color(0xFFF5F5F5);
  final Color userMessageColor = const Color(0xFFE3F2FD);
  final Color ratingColor = const Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    //_initializeFirebase();
    _checkLocationPermission();
    _addWelcomeMessage();
  }

  Future<void> _addWelcomeMessage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _addBotMessage(
      "👋 Welcome to Halal Bites! I can help you find halal restaurants near you. "
          "Try asking:\n\n"
          "• \"Find halal restaurants nearby\"\n"
          "• \"Best halal food in London\"\n"
          "• \"Show me halal burgers\"",
    );
  }

  Future<void> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied ||
        status == LocationPermission.deniedForever) {
      setState(() => _showLocationPermissionBanner = true);
    } else {
      _getCurrentLocation();
    }
  }

  // Future<void> _initializeFirebase() async {
  //   _chatCollection = _fireStore.collection('chat_history');
  //   _loadMessages();
  // }
  //
  // Future<void> _loadMessages() async {
  //   try {
  //     final snapshot = await _chatCollection
  //         .orderBy('timestamp', descending: false)
  //         .get();
  //
  //     List<dynamic> loadedRestaurants = [];
  //
  //     setState(() {
  //       messages = snapshot.docs.map((doc) {
  //         final message = {
  //           'role': doc['role'],
  //           'text': doc['text'],
  //           'meta': doc['meta'] ?? '',
  //           'timestamp': doc['timestamp'],
  //         };
  //
  //         if (message['role'] == 'bot' && message['meta'].isNotEmpty) {
  //           try {
  //             final meta = jsonDecode(message['meta']);
  //             if (meta is Map<String, dynamic> && meta.containsKey('place_id')) {
  //               if (!loadedRestaurants.any((r) => r['place_id'] == meta['place_id'])) {
  //                 loadedRestaurants.add(meta);
  //               }
  //             }
  //           } catch (e) {
  //             debugPrint('Error parsing restaurant meta: $e');
  //           }
  //         }
  //
  //         return message;
  //       }).toList();
  //
  //       _restaurants = loadedRestaurants;
  //     });
  //
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (_scrollController.hasClients) {
  //         _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint('Error loading messages: $e');
  //   }
  // }
  //
  // Future<void> _saveMessage(Map<String, dynamic> message) async {
  //   try {
  //     await _chatCollection.add({
  //       'role': message['role'],
  //       'text': message['text'],
  //       'meta': message['meta'] ?? '',
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //   } catch (e) {
  //     debugPrint('Error saving message: $e');
  //   }
  // }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _showLocationPermissionBanner = true);
        return;
      }

      setState(() => _showLocationPermissionBanner = false);

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      setState(() => _userPosition = position);
    } catch (e) {
      debugPrint('Error getting location: $e');
      _addBotMessage('Could not determine your location. Showing results for central London instead.');
    }
  }

  Future<void> fetchNearbyHalalRestaurants(String query) async {
    if (_isLoadingRestaurants) return;

    setState(() {
      _isLoadingRestaurants = true;
      _isSendingMessage = true;
    });

    final location = _userPosition != null
        ? '${_userPosition!.latitude},${_userPosition!.longitude}'
        : '51.507218, -0.127586'; // Default to London

    _addBotMessage(
      '🔍 Searching for halal restaurants near you...',
    );

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
            'query=halal+restaurants+in+$query&'
            'location=$location&radius=50000&key=$googleApiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        _addBotMessage(' Could not fetch restaurants. Please try again later.');
        return;
      }

      final data = jsonDecode(response.body);
      final results = data['results'] as List;

      if (results.isEmpty) {
        _addBotMessage('No halal restaurants found nearby. Try expanding your search area.');
        return;
      }

      setState(() {
        _restaurants = results;
      });

      _addBotMessage(' Found ${results.length} halal restaurants:');

      // Process first 3 restaurants immediately, others in background
      for (int i = 0; i < results.length; i++) {
        if (i < 3) {
          await _processRestaurantResult(results[i]);
        } else {
          _processRestaurantResult(results[i]); // Process in background
        }
      }
    } catch (e) {
      _addBotMessage(' Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingRestaurants = false;
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _processRestaurantResult(dynamic r) async {
    try {
      final placeId = r['place_id'];
      final detailsUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?'
              'place_id=$placeId&fields=name,formatted_address,website,photos,geometry,rating,user_ratings_total&key=$googleApiKey'
      );

      final detailsResponse = await http.get(detailsUrl);
      final detailsData = jsonDecode(detailsResponse.body)['result'];

      final name = r['name'];
      final address = r['formatted_address'];
      final rating = detailsData['rating']?.toString() ?? 'N/A';
      final ratingCount = detailsData['user_ratings_total']?.toString() ?? '0';
      final photoRef = r['photos']?[0]['photo_reference'];
      final imageUrl = photoRef != null
          ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoRef&key=$googleApiKey'
          : null;
      final website = detailsData['website']?.toString() ?? '';
      r['website'] = website;

      // Get coordinates for map link
      final lat = detailsData['geometry']['location']['lat'];
      final lng = detailsData['geometry']['location']['lng'];
      final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      final messageText = '''
      ${imageUrl != null ? '![Image]($imageUrl)' : ''}
      *${name}* 
      ${_buildRatingWidget(double.tryParse(rating) ?? 0, int.tryParse(ratingCount) ?? 0)}
      📍 ${address}
      ${website.isNotEmpty ? '[🌐 Visit Website]($website)' : ''}
      [🗺️ View on Map]($mapUrl)
      ''';

      _addBotMessage(messageText, meta: r);
    } catch (e) {
      debugPrint('Error processing restaurant: $e');
    }
  }

  Widget _buildRatingWidget(double rating, int ratingCount) {
    return Row(
      children: [
        Icon(Icons.star, color: ratingColor, size: 18),
        Text(' ${rating.toStringAsFixed(1)}', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(' ($ratingCount)', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _addBotMessage(String text, {dynamic meta}) {
    final message = {
      'role': 'bot',
      'text': text,
      'meta': meta != null ? jsonEncode(meta) : '',
    };
    setState(() => messages.add(message));
    //_saveMessage(message);
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    final message = {
      'role': 'user',
      'text': text,
      'meta': '',
    };
    setState(() => messages.add(message));
   // _saveMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty || _isSendingMessage) return;

    _addUserMessage(userMessage);
    _controller.clear();
    setState(() => _isSendingMessage = true);

    final lower = userMessage.toLowerCase();
    if (lower.contains("halal") &&
        (lower.contains("restaurant") || lower.contains("food") ||
            lower.contains("places") || lower.contains("eat"))) {
      _lastQuery = "near me";
      await fetchNearbyHalalRestaurants(_lastQuery);
      setState(() => _isSendingMessage = false);
      return;
    }

    try {
      final url = Uri.parse("https://api.openai.com/v1/chat/completions");
      final response = await http.post(url,
        headers: {
          'Authorization': 'Bearer $openAiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4",
          "messages": messages.where((m) => !m['text'].toString().startsWith('!['))
              .map((m) => {
            "role": m['role'] == 'user' ? 'user' : 'assistant',
            "content": m['text']
          }).toList()
        }),
      );

      if (response.statusCode == 200) {
        final content = jsonDecode(response.body)['choices'][0]['message']['content'];
        _addBotMessage(content);
      } else {
        _addBotMessage(' Sorry, I encountered an error. Please try again.');
      }
    } catch (e) {
      _addBotMessage(' Error: ${e.toString()}');
    } finally {
      setState(() => _isSendingMessage = false);
    }
  }

  Widget _buildImageWithNavigation(String imageUrl, Map<String, dynamic> restaurantData) {
    return GestureDetector(
      onTap: () => _showRestaurantDetails(restaurantData, imageUrl),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.restaurant, size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRestaurantDetails(Map<String, dynamic> restaurantData, String? imageUrl) async {
    final placeId = restaurantData['place_id'];

    final detailsUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,rating,formatted_address,website,reviews,opening_hours,photos,formatted_phone_number,user_ratings_total,editorial_summary,geometry'
          '&key=$googleApiKey',
    );

    try {
      final detailsRes = await http.get(detailsUrl);
      final details = jsonDecode(detailsRes.body)['result'];

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
      final lat = details['geometry']['location']['lat'];
      final lng = details['geometry']['location']['lng'];
      final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final phone = details['formatted_phone_number'] ?? 'Not available';
      final photos = (details['photos'] as List?) ?? [];
      final menuPhotos = photos.take(10).map((p) {
        return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photo_reference=${p['photo_reference']}&key=$googleApiKey';
      }).toList();
      final description = details['editorial_summary']?['overview'] ??
          'A wonderful dining experience offering delicious cuisine in a welcoming atmosphere. '
              'Known for its excellent service and quality ingredients.';

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(
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
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load details: ${e.toString()}'))
        );
      }
    }
  }
  List<Widget> _parseMessageText(Map<String, dynamic> msg) {
    final widgets = <Widget>[];
    final text = msg['text'] ?? '';
    final lines = text.split('\n');
    final metaJson = msg['meta'];
    Map<String, dynamic>? restaurantData = metaJson != null && metaJson.isNotEmpty
        ? jsonDecode(metaJson)
        : null;

    bool foundName = false;
    bool foundAddress = false;

    for (var line in lines) {
      final imgMatch = RegExp(r'!\[(.*?)\]\((.*?)\)').firstMatch(line);
      final linkMatch = RegExp(r'\[(.*?)\]\((.*?)\)').firstMatch(line);

      if (imgMatch != null && restaurantData != null) {
        // Full width image
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: _buildImageWithNavigation(imgMatch.group(2)!, restaurantData),
          ),
        );
      } else if (linkMatch != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: () => _launchUrl(linkMatch.group(2)!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  linkMatch.group(1)!.contains('🌐')
                      ? const Icon(Icons.language, size: 16, color: Colors.blue)
                      : const Icon(Icons.map, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    linkMatch.group(1)!.replaceAll('🌐', '').replaceAll('🗺️', '').trim(),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (line.trim().isNotEmpty) {
        if (line.trim().startsWith('*') && line.trim().endsWith('*')) {
          // Restaurant name
          foundName = true;
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 8),
              child: Text(
                line.trim().replaceAll('*', ''),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        } else if (line.trim().startsWith('📍')) {
          // Address
          foundAddress = true;
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                line.trim(),
                style: TextStyle(
                  color: Colors.grey[800],
                ),
              ),
            ),
          );
        }
        // Skip other text if it's between name and address
        else if (!foundName || foundAddress) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                line.trim(),
                style: TextStyle(
                  color: Colors.grey[800],
                ),
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  Widget _buildViewAllButton() {
    final hasRestaurantMessages = messages.any((msg) =>
    msg['role'] == 'bot' && msg['meta'] != null && msg['meta'].isNotEmpty);

    if (!hasRestaurantMessages || _isLoadingRestaurants) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllRestaurantsScreen(
                  restaurants: _restaurants,
                  googleApiKey: googleApiKey,
                ),
              ),
            );
          },
          child: const Text(
            'View All Restaurants',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      'Find halal restaurants',
      'Best halal food near me',
      'Halal food open now',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: quickReplies.map((reply) {
          return Padding(
              padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
          label: Text(reply),
          onPressed: () => sendMessage(reply),
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(color: primaryColor),
          shape: StadiumBorder(
          side: BorderSide(color: primaryColor.withOpacity(0.2)),
          ),
          ));
        }).toList(),
      ),
    );
  }

  Widget _buildLocationPermissionBanner() {
    if (!_showLocationPermissionBanner) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enable location to find restaurants near you',
              style: TextStyle(color: Colors.orange[800]),
            ),
          ),
          TextButton(
            onPressed: _getCurrentLocation,
            child: Container(
              height: 40,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryColor,
                  width: 1
                )
              ),
              child: Center(
                  child: Text(
                  'Enable',
                style: TextStyle(
                  color: AppColors.primaryColor
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Halal Bites Finder",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildLocationPermissionBanner(),
                    _buildQuickReplies(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.85,
                              ),
                              child: Card(
                                elevation: 0,
                                color: isUser ? userMessageColor : botMessageColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                    bottomRight: isUser
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _parseMessageText(msg),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildViewAllButton(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask about halal restaurants...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        suffixIcon: _isSendingMessage
                            ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted: (text) => sendMessage(text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) sendMessage(text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}