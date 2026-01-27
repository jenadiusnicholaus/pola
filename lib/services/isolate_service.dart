import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_isolate/flutter_isolate.dart';

/// A service to offload heavy computations to background isolates
/// to keep the main UI thread responsive.
/// 
/// Uses `flutter_isolate` package which supports Flutter plugins inside isolates,
/// and Flutter's `compute` function for simple computations.
/// 
/// Usage examples:
/// ```dart
/// // Run heavy API call in background isolate (with plugin support)
/// final result = await IsolateService.runInIsolate(myHeavyFunction, params);
/// 
/// // Parse large JSON in background
/// final data = await IsolateService.parseJson(largeJsonString);
/// 
/// // Filter large list in background
/// final filtered = await IsolateService.filterListInBackground(
///   items,
///   (item) => item.title.contains(searchQuery),
/// );
/// ```
class IsolateService {
  static final IsolateService _instance = IsolateService._internal();
  factory IsolateService() => _instance;
  IsolateService._internal();

  // Track running isolates for cleanup
  static final List<FlutterIsolate> _runningIsolates = [];

  /// Run a function in a FlutterIsolate with plugin support
  /// Use this for heavy operations that need Firebase, Dio, etc.
  /// 
  /// The function MUST be a top-level or static function annotated with
  /// @pragma('vm:entry-point')
  static Future<R> runInIsolate<T, R>(
    Future<R> Function(T) function,
    T argument,
  ) async {
    return flutterCompute(function, argument);
  }

  /// Spawn a long-running isolate that can use Flutter plugins
  /// Returns the FlutterIsolate for control (pause/resume/kill)
  /// 
  /// The entryPoint MUST be a top-level or static function annotated with
  /// @pragma('vm:entry-point')
  static Future<FlutterIsolate> spawnIsolate<T>(
    void Function(T) entryPoint,
    T argument,
  ) async {
    final isolate = await FlutterIsolate.spawn(entryPoint, argument);
    _runningIsolates.add(isolate);
    return isolate;
  }

  /// Kill all running isolates (cleanup)
  static void killAllIsolates() {
    for (final isolate in _runningIsolates) {
      isolate.kill();
    }
    _runningIsolates.clear();
    FlutterIsolate.killAll();
  }

  /// Parse JSON in a background isolate
  /// Useful for large API responses
  static Future<dynamic> parseJson(String jsonString) async {
    return compute(_parseJsonInBackground, jsonString);
  }

  static dynamic _parseJsonInBackground(String jsonString) {
    return json.decode(jsonString);
  }

  /// Encode data to JSON in a background isolate
  /// Useful for large request payloads
  static Future<String> encodeJson(dynamic data) async {
    return compute(_encodeJsonInBackground, data);
  }

  static String _encodeJsonInBackground(dynamic data) {
    return json.encode(data);
  }

  /// Process a list of items in a background isolate
  /// Useful for transforming large lists of data
  static Future<List<R>> processListInBackground<T, R>(
    List<T> items,
    R Function(T) processor,
  ) async {
    // For small lists, process on main thread
    if (items.length < 100) {
      return items.map(processor).toList();
    }

    // For larger lists, use compute
    return compute(
      _processListInIsolate<T, R>,
      _ProcessListParams(items, processor),
    );
  }

  static List<R> _processListInIsolate<T, R>(_ProcessListParams<T, R> params) {
    return params.items.map(params.processor).toList();
  }

  /// Run multiple API calls in parallel and collect results
  /// Returns a map of keys to their results (or errors)
  static Future<Map<String, ApiResult>> runParallelApiCalls(
    Map<String, Future<dynamic> Function()> calls,
  ) async {
    final results = <String, ApiResult>{};
    final futures = <String, Future<dynamic>>{};

    // Start all calls in parallel
    for (final entry in calls.entries) {
      futures[entry.key] = entry.value();
    }

    // Wait for all to complete
    for (final entry in futures.entries) {
      try {
        final result = await entry.value;
        results[entry.key] = ApiResult.success(result);
      } catch (e) {
        results[entry.key] = ApiResult.error(e.toString());
      }
    }

    return results;
  }

  /// Heavy string processing in background
  static Future<String> processStringInBackground(
    String input,
    String Function(String) processor,
  ) async {
    return compute(
      _processStringInIsolate,
      _ProcessStringParams(input, processor),
    );
  }

  static String _processStringInIsolate(_ProcessStringParams params) {
    return params.processor(params.input);
  }

  /// Filter a large list in background
  static Future<List<T>> filterListInBackground<T>(
    List<T> items,
    bool Function(T) predicate,
  ) async {
    if (items.length < 100) {
      return items.where(predicate).toList();
    }

    return compute(
      _filterListInIsolate<T>,
      _FilterListParams(items, predicate),
    );
  }

  static List<T> _filterListInIsolate<T>(_FilterListParams<T> params) {
    return params.items.where(params.predicate).toList();
  }

  /// Sort a large list in background
  static Future<List<T>> sortListInBackground<T>(
    List<T> items,
    int Function(T a, T b) comparator,
  ) async {
    if (items.length < 100) {
      return List<T>.from(items)..sort(comparator);
    }

    return compute(
      _sortListInIsolate<T>,
      _SortListParams(items, comparator),
    );
  }

  static List<T> _sortListInIsolate<T>(_SortListParams<T> params) {
    final list = List<T>.from(params.items);
    list.sort(params.comparator);
    return list;
  }

  /// Search/filter text in background (useful for search features)
  static Future<List<T>> searchInBackground<T>(
    List<T> items,
    String query,
    String Function(T) getSearchableText,
  ) async {
    if (items.isEmpty || query.isEmpty) {
      return items;
    }

    return compute(
      _searchInIsolate<T>,
      _SearchParams(items, query.toLowerCase(), getSearchableText),
    );
  }

  static List<T> _searchInIsolate<T>(_SearchParams<T> params) {
    return params.items.where((item) {
      final text = params.getSearchableText(item).toLowerCase();
      return text.contains(params.query);
    }).toList();
  }
}

/// Result wrapper for parallel API calls
class ApiResult {
  final bool isSuccess;
  final dynamic data;
  final String? error;

  ApiResult._({required this.isSuccess, this.data, this.error});

  factory ApiResult.success(dynamic data) => ApiResult._(
        isSuccess: true,
        data: data,
      );

  factory ApiResult.error(String message) => ApiResult._(
        isSuccess: false,
        error: message,
      );
}

/// Helper classes for isolate parameters (must be sendable between isolates)
class _ProcessListParams<T, R> {
  final List<T> items;
  final R Function(T) processor;
  _ProcessListParams(this.items, this.processor);
}

class _ProcessStringParams {
  final String input;
  final String Function(String) processor;
  _ProcessStringParams(this.input, this.processor);
}

class _FilterListParams<T> {
  final List<T> items;
  final bool Function(T) predicate;
  _FilterListParams(this.items, this.predicate);
}

class _SortListParams<T> {
  final List<T> items;
  final int Function(T a, T b) comparator;
  _SortListParams(this.items, this.comparator);
}

class _SearchParams<T> {
  final List<T> items;
  final String query;
  final String Function(T) getSearchableText;
  _SearchParams(this.items, this.query, this.getSearchableText);
}

/// Extension for parsing large JSON responses using isolate
extension DioResponseIsolate on dio.Response {
  /// Parse JSON data in a background isolate if the response is large
  Future<dynamic> parseInBackground() async {
    if (data == null) return null;

    // If already parsed (Dio auto-parses JSON by default), return directly
    if (data is Map || data is List) {
      return data;
    }

    // If string, parse in background for large responses
    if (data is String) {
      final str = data as String;
      if (str.length > 10000) {
        // Parse large JSON (>10KB) in background
        return IsolateService.parseJson(str);
      }
      return json.decode(str);
    }

    return data;
  }
}
