import 'dart:typed_data';

/// Lightweight in-memory cache with TTL support.
/// Works on both web and mobile — no extra packages needed.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  final Map<String, _CacheEntry<dynamic>> _cache = {};

  /// Default TTL: 5 minutes
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Store a value with an optional TTL
  void put<T>(String key, T value, {Duration ttl = defaultTTL}) {
    _cache[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  /// Get a cached value, or null if expired/missing
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  /// Check if a valid (non-expired) entry exists
  bool has(String key) => get(key) != null;

  /// Remove a specific key
  void remove(String key) => _cache.remove(key);

  /// Remove all entries matching a prefix (e.g. 'properties_')
  void removeByPrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear all cached data
  void clear() => _cache.clear();

  // ── Image cache (separate, longer TTL) ──

  static const int _maxImageCacheSize = 100;
  final Map<String, _CacheEntry<Uint8List>> _imageCache = {};

  /// Cache image bytes
  void putImage(String url, Uint8List bytes) {
    // Evict oldest if at capacity
    if (_imageCache.length >= _maxImageCacheSize) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[url] = _CacheEntry(
      bytes,
      DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  /// Get cached image bytes
  Uint8List? getImage(String url) {
    final entry = _imageCache[url];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiry)) {
      _imageCache.remove(url);
      return null;
    }
    return entry.value;
  }

  /// Clear image cache
  void clearImages() => _imageCache.clear();
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;
  _CacheEntry(this.value, this.expiry);
}
