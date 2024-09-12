import 'dart:async';
import 'package:flutter/material.dart';

import '../services/pixabay_api_service.dart';

class GalleryProvider extends ChangeNotifier {
  final PixabayApiService _pixabayApiService;
  List<dynamic> _images = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String _searchQuery = 'nature'; // Default search query
  int _page = 1;
  bool _hasMore = true;
  Timer? _debounce;

  List<dynamic> get images => _images;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;

  GalleryProvider(this._pixabayApiService);

  /// Fetch images for the initial load
  Future<void> fetchImages() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newImages = await _pixabayApiService.fetchImages(
          query: _searchQuery, page: _page);
      if (newImages.isEmpty) {
        _hasMore = false;
      }
      _images.addAll(newImages);
    } catch (e) {
      debugPrint('Error fetching images: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch more images when the user scrolls down
  Future<void> fetchMoreImages() async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    _page += 1;
    notifyListeners();

    try {
      final moreImages = await _pixabayApiService.fetchImages(
          query: _searchQuery, page: _page);
      if (moreImages.isEmpty) {
        _hasMore = false;
      }
      _images.addAll(moreImages);
    } catch (e) {
      debugPrint('Error fetching more images: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /// Handle search input with debounce
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query != _searchQuery) {
        _searchQuery = query;
        _page = 1;
        _images.clear();
        _hasMore = true;
        fetchImages();
      }
    });
  }
}
