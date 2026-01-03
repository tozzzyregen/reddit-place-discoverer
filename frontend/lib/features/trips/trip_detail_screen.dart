import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trips_provider.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  final String title;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    
    // Find the specific trip
    final trip = trips.firstWhere(
      (t) => t['id'] == tripId,
      orElse: () => null,
    );

    final itinerary = (trip?['itinerary'] as List?) ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: itinerary.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: itinerary.length,
              itemBuilder: (context, index) {
                final place = itinerary[index];
                return _PlaceCard(
                  place: place,
                  onRemove: () async {
                    final placeName = place['name'] ?? '';
                    final success = await ref
                        .read(tripsProvider.notifier)
                        .removeFromTrip(tripId, placeName);

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "$placeName"'),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.place_outlined, color: Colors.grey[700], size: 64),
          const SizedBox(height: 16),
          Text(
            'No places saved yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for places and save them here',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final dynamic place;
  final VoidCallback onRemove;

  const _PlaceCard({
    required this.place,
    required this.onRemove,
  });

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final name = place['name'] ?? 'Unknown Place';
    final verdict = place['verdict'] ?? '';
    final score = (place['score'] ?? 0).toDouble();
    final address = place['address'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getScoreColor(score).withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                color: _getScoreColor(score),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (verdict.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                verdict,
                style: const TextStyle(
                  color: Color(0xFFFF4500),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

