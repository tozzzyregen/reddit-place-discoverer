import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class AnalysisState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  AnalysisState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  AnalysisState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return AnalysisState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => AnalysisState();

  Future<void> analyze(String placeName) async {
    state = AnalysisState(isLoading: true);

    try {
      final result = await ApiClient.get('analyze/?name=$placeName');

      if (result != null && result is Map<String, dynamic>) {
        state = AnalysisState(data: result);
      } else {
        state = AnalysisState(error: 'Failed to analyze location');
      }
    } catch (e) {
      state = AnalysisState(error: e.toString());
    }
  }

  void clear() {
    state = AnalysisState();
  }
}

final analysisProvider = NotifierProvider<AnalysisNotifier, AnalysisState>(
  AnalysisNotifier.new,
);

