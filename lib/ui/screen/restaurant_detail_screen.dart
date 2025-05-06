import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String rating;
  final int reviewCount;
  final String address;
  final String website;
  final String openingHours;
  final List<Map<String, dynamic>> reviews;
  final List<String> menuPhotos;
  final String phone;
  final String description;
  final String mapUrl;

  const RestaurantDetailScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.website,
    required this.openingHours,
    required this.reviews,
    required this.menuPhotos,
    required this.phone,
    required this.description,
    required this.mapUrl,
  });

  Future<void> _launchLink(String url) async {
    if (url.isEmpty) {
      debugPrint("No URL provided");
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,

                  shadows: [
                  Shadow(
                  color: Colors.white,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                  )
                  ],
                ),
              ),
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, size: 100),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and basic info
                  _buildRatingSection(context),
                  const SizedBox(height: 20),

                  // Description
                  _buildDescriptionSection(),
                  const SizedBox(height: 20),

                  // Contact & Hours row
                  _buildContactAndHoursRow(context),
                  const SizedBox(height: 20),

                  // Menu section
                  _buildMenuSection(),
                  const SizedBox(height: 20),

                  // Reviews section
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchLink(mapUrl),
        icon: const Icon(Icons.directions),
        label: const Text('Directions'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                rating,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($reviewCount reviews)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildContactAndHoursRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildContactCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildOpeningHoursCard()),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContactCard(),
              const SizedBox(height: 16),
              _buildOpeningHoursCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactItem(Icons.location_on, address, onTap: () => _launchLink(mapUrl)),
            _buildContactItem(Icons.phone, phone, onTap: () => _launchLink('tel:$phone')),
            _buildContactItem(Icons.language, 'Visit Website', onTap: () => _launchLink(website)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: onTap != null ? Colors.blue : Colors.black,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHoursCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opening Hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...openingHours.split('\n').map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(line, style: const TextStyle(fontSize: 16)),
            )),
          ],
        ),
      ),
    );
  }
  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (menuPhotos.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: menuPhotos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      menuPhotos[index],
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const Text('No reviews available', style: TextStyle(fontSize: 16))
        else
          ...reviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review['profile_photo_url']?.isNotEmpty == true
                      ? NetworkImage(review['profile_photo_url'])
                      : null,
                  child: review['profile_photo_url']?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < (review['rating'] ?? 0)
                              ? Colors.amber
                              : Colors.grey,
                        )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['text'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              review['relative_time_description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}