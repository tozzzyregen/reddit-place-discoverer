import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class SearchNotifier extends Notifier<List<dynamic>> {
  @override
  List<dynamic> build() => [];

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }

    final results = await ApiClient.get('search/query?q=$query');

    if (results != null && results is List) {
      state = results;
    } else {
      state = [];
    }
  }

  void clear() {
    state = [];
  }
}

final searchProvider = NotifierProvider<SearchNotifier, List<dynamic>>(
  SearchNotifier.new,
);

