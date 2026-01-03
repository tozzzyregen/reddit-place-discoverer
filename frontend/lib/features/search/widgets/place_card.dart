import 'package:flutter/material.dart';
import '../detail_screen.dart';

class PlaceCard extends StatelessWidget {
  final dynamic place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final name = place['name'] ?? 'Unknown';
    final address = place['formatted_address'] ?? '';
    final rating = place['rating'];
    final userRatingsTotal = place['user_ratings_total'];
    final openNow = place['open_now'];
    final photoRef = place['photo_reference'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              placeName: name,
              address: address,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.grey[900],
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 150,
              width: double.infinity,
              child: photoRef != null
                  ? Image.network(
                      'https://places.googleapis.com/v1/$photoRef/media?maxWidthPx=400&key=${const String.fromEnvironment('GOOGLE_API_KEY', defaultValue: '')}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildPlaceholder();
                      },
                    )
                  : _buildPlaceholder(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Place Name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Rating Row
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (userRatingsTotal != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($userRatingsTotal)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      // Status Badge
                      if (openNow != null) _buildStatusBadge(openNow),
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

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.place,
          color: Color(0xFFFF4500),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

