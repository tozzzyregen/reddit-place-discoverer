// ============================================
// NOTE: "placeData" needs to match the backend expectation exactly.
// Expected format: { "name": String, "verdict": String, "score": double, "address": String }
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';

class TripsNotifier extends Notifier<List<dynamic>> {
  @override
  List<dynamic> build() => [];

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> loadTrips() async {
    if (_userId == null) return;

    final result = await ApiClient.get('trips/$_userId');

    if (result != null && result is List) {
      state = result;
    }
  }

  Future<bool> createTrip(String title) async {
    if (_userId == null) return false;

    try {
      final response = await ApiClient.post('trips/', {
        'user_id': _userId,
        'title': title,
      });

      if (response != null) {
        await loadTrips();
        return true;
      }
      return false;
    } catch (e) {
      print('Create Trip Error: $e');
      return false;
    }
  }

  Future<bool> addToTrip(String tripId, Map<String, dynamic> placeData) async {
    try {
      final response = await ApiClient.post('trips/add', {
        'trip_id': tripId,
        'place_data': placeData,
      });

      if (response != null && response['status'] == 'success') {
        await loadTrips();
        return true;
      }
      return false;
    } catch (e) {
      print('Add to Trip Error: $e');
      return false;
    }
  }

  Future<bool> removeFromTrip(String tripId, String placeName) async {
    try {
      final response = await ApiClient.post('trips/remove', {
        'trip_id': tripId,
        'place_name': placeName,
      });

      if (response != null && response['status'] == 'updated') {
        // Update state locally for instant UI refresh
        state = state.map((trip) {
          if (trip['id'] == tripId) {
            final itinerary = List<dynamic>.from(trip['itinerary'] ?? []);
            itinerary.removeWhere((item) => item['name'] == placeName);
            return {...trip, 'itinerary': itinerary};
          }
          return trip;
        }).toList();
        return true;
      }
      return false;
    } catch (e) {
      print('Remove from Trip Error: $e');
      return false;
    }
  }
}

final tripsProvider = NotifierProvider<TripsNotifier, List<dynamic>>(
  TripsNotifier.new,
);

