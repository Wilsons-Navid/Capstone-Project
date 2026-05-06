import 'dart:math' as math;

/// Safe collection access extensions to prevent buffer overflows and index errors
extension SafeList<T> on List<T> {
  /// Safely get element at index, returns null if out of bounds
  T? safeElementAt(int index) {
    return (index >= 0 && index < length) ? this[index] : null;
  }

  /// Safely get first element, returns null if list is empty
  T? get safeFirst => isEmpty ? null : first;

  /// Safely get last element, returns null if list is empty
  T? get safeLast => isEmpty ? null : last;

  /// Safely take elements with bounds checking
  List<T> safeTake(int count) {
    final safeCount = math.max(0, math.min(count, length));
    return take(safeCount).toList();
  }

  /// Safely skip elements with bounds checking
  List<T> safeSkip(int count) {
    final safeCount = math.max(0, math.min(count, length));
    return skip(safeCount).toList();
  }

  /// Safely get a sublist with bounds checking
  List<T> safeSublist(int start, [int? end]) {
    final safeStart = math.max(0, math.min(start, length));
    final safeEnd = end != null ? math.max(safeStart, math.min(end, length)) : length;
    return sublist(safeStart, safeEnd);
  }

  /// Safely remove element at index
  bool safeRemoveAt(int index) {
    if (index >= 0 && index < length) {
      removeAt(index);
      return true;
    }
    return false;
  }

  /// Safely insert element at index
  bool safeInsert(int index, T element) {
    if (index >= 0 && index <= length) {
      insert(index, element);
      return true;
    }
    return false;
  }

  /// Get elements in safe range
  List<T> safeRange(int start, int end) {
    final safeStart = math.max(0, math.min(start, length));
    final safeEnd = math.max(safeStart, math.min(end, length));
    return safeSublist(safeStart, safeEnd);
  }
}

/// Safe string operations to prevent overflow
extension SafeString on String {
  /// Safely get substring with bounds checking
  String safeSubstring(int startIndex, [int? endIndex]) {
    final safeStart = math.max(0, math.min(startIndex, length));
    final safeEnd = endIndex != null ? 
        math.max(safeStart, math.min(endIndex, length)) : length;
    return substring(safeStart, safeEnd);
  }

  /// Safely get character at index
  String? safeCharAt(int index) {
    return (index >= 0 && index < length) ? this[index] : null;
  }

  /// Safe string truncation with ellipsis
  String safeTruncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    
    final truncateLength = math.max(0, maxLength - ellipsis.length);
    return safeSubstring(0, truncateLength) + ellipsis;
  }

  /// Split string safely with limit
  List<String> safeSplit(Pattern pattern, {int? limit}) {
    try {
      final parts = split(pattern);
      if (limit != null && limit > 0 && parts.length > limit) {
        final result = parts.safeTake(limit - 1);
        final remaining = parts.safeSkip(limit - 1).join(pattern.toString());
        if (remaining.isNotEmpty) {
          result.add(remaining);
        }
        return result;
      }
      return parts;
    } catch (e) {
      return [this]; // Return original string if split fails
    }
  }

  /// Get file extension safely
  String get safeFileExtension {
    final parts = safeSplit('.');
    return parts.length > 1 ? parts.safeLast?.toLowerCase() ?? '' : '';
  }
}

/// Safe map operations
extension SafeMap<K, V> on Map<K, V> {
  /// Safely get value with type checking
  T? safeGet<T>(K key) {
    final value = this[key];
    return (value is T) ? value : null;
  }

  /// Get value or default
  V safeGetOrDefault(K key, V defaultValue) {
    return this[key] ?? defaultValue;
  }

  /// Safely cast value to specific type
  T? safeCast<T>(K key) {
    try {
      final value = this[key];
      return (value is T) ? value : null;
    } catch (e) {
      return null;
    }
  }
}

/// Bounds checking utilities
class BoundsChecker {
  /// Check if index is within bounds
  static bool isValidIndex(int index, int length) {
    return index >= 0 && index < length;
  }

  /// Check if range is valid
  static bool isValidRange(int start, int end, int length) {
    return start >= 0 && start <= end && end <= length;
  }

  /// Clamp value to valid range
  static int clampIndex(int index, int length) {
    return math.max(0, math.min(index, length - 1));
  }

  /// Clamp range to valid bounds
  static (int, int) clampRange(int start, int end, int length) {
    final safeStart = math.max(0, math.min(start, length));
    final safeEnd = math.max(safeStart, math.min(end, length));
    return (safeStart, safeEnd);
  }
}

/// Memory-safe buffer operations
class SafeBuffer {
  static const int defaultMaxSize = 1024 * 1024; // 1MB default
  
  final int maxSize;
  final List<int> _buffer = [];
  
  SafeBuffer({this.maxSize = defaultMaxSize});
  
  /// Add data to buffer with size checking
  bool addData(List<int> data) {
    if (_buffer.length + data.length > maxSize) {
      return false; // Buffer would overflow
    }
    _buffer.addAll(data);
    return true;
  }
  
  /// Get data from buffer safely
  List<int> getData([int? start, int? end]) {
    final safeStart = start != null ? math.max(0, math.min(start, _buffer.length)) : 0;
    final safeEnd = end != null ? math.max(safeStart, math.min(end, _buffer.length)) : _buffer.length;
    return _buffer.safeSublist(safeStart, safeEnd);
  }
  
  /// Clear buffer
  void clear() => _buffer.clear();
  
  /// Get current size
  int get size => _buffer.length;
  
  /// Check if buffer has space
  bool hasSpace(int additionalBytes) {
    return _buffer.length + additionalBytes <= maxSize;
  }
}