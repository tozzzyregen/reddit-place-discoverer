// ============================================
// For Android, you MUST set minSdkVersion to 19 or higher
// in android/app/build.gradle for WebView to work.
// Also add <uses-permission android:name="android.permission.INTERNET"/>
// in AndroidManifest if not already present.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analysis_provider.dart';
import 'widgets/tiktok_embed.dart';
import '../trips/trips_provider.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final String placeName;
  final String address;

  const DetailScreen({
    super.key,
    required this.placeName,
    required this.address,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analysisProvider.notifier).analyze(widget.placeName);
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  void _showSaveToTripDialog(Map<String, dynamic> analysisData) {
    // Load trips first
    ref.read(tripsProvider.notifier).loadTrips();

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final trips = ref.watch(tripsProvider);

          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Save to Trip', style: TextStyle(color: Colors.white)),
            content: trips.isEmpty
                ? const Text(
                    'No trips yet. Create a trip first!',
                    style: TextStyle(color: Colors.grey),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return ListTile(
                          leading: const Icon(Icons.map, color: Color(0xFFFF4500)),
                          title: Text(
                            trip['title'] ?? 'Untitled',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            final placeData = {
                              'name': widget.placeName,
                              'address': widget.address,
                              'verdict': analysisData['verdict'],
                              'score': analysisData['reddit_score'],
                            };

                            final success = await ref
                                .read(tripsProvider.notifier)
                                .addToTrip(trip['id'], placeData);

                            if (context.mounted) Navigator.pop(context);

                            if (success && mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Saved to ${trip['title']}!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.placeName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: analysisState.isLoading
          ? _buildLoading()
          : analysisState.error != null
              ? _buildError(analysisState.error!)
              : analysisState.data != null
                  ? _buildContent(analysisState.data!)
                  : _buildLoading(),
      floatingActionButton: analysisState.data != null
          ? FloatingActionButton(
              onPressed: () => _showSaveToTripDialog(analysisState.data!),
              backgroundColor: const Color(0xFFFF4500),
              child: const Icon(Icons.bookmark_add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFF4500)),
          SizedBox(height: 24),
          Text(
            'Consulting Reddit...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Analyzing traveler discussions',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Analysis Failed',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final verdict = data['verdict'] ?? 'No Verdict';
    final score = (data['reddit_score'] ?? 0).toDouble();
    final pros = List<String>.from(data['pros'] ?? []);
    final cons = List<String>.from(data['cons'] ?? []);
    final scams = List<String>.from(data['scams'] ?? []);
    final bestFor = List<String>.from(data['best_for'] ?? []);
    final socialLinks = List<String>.from(data['social_links'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict Header
          Center(
            child: Text(
              verdict,
              style: const TextStyle(
                color: Color(0xFFFF4500),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              widget.address,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Reddit Score
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _getScoreColor(score).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getScoreColor(score), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Reddit Score',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Best For Tags
          if (bestFor.isNotEmpty) ...[
            const Text(
              'BEST FOR',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bestFor.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4500).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Color(0xFFFF4500), fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Pros & Cons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pros
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROS',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pros.map((pro) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.add_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pro,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Cons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONS',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...cons.map((con) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.remove_circle, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  con,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Scams Warning
          if (scams.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'WATCH OUT FOR',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...scams.map((scam) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $scam',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // TikTok Embeds
          if (socialLinks.isNotEmpty) ...[
            const Text(
              'WATCH ON TIKTOK',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 520,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: socialLinks.length,
                itemBuilder: (context, index) {
                  return TikTokEmbed(videoUrl: socialLinks[index]);
                },
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

