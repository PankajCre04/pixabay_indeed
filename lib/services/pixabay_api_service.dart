import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../handlers/expections/custom_exceptions.dart';

class PixabayApiService {
  final String? _apiKey =
      dotenv.env['PIXABAY_API_KEY']; // Load API key from environment variable
  final Logger _logger = Logger('PixabayApiService');
  final int _timeoutSeconds = 15;

  PixabayApiService() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          'Pixabay API Key is missing. Please set it in the .env file.');
    }
  }

  /// Fetches images from Pixabay API with optional query and page parameters
  Future<List<dynamic>> fetchImages(
      {required String query, int page = 1, int perPage = 20}) async {
    final uri = Uri.parse(
        'https://pixabay.com/api/?key=$_apiKey&q=$query&image_type=photo&page=$page&per_page=$perPage');
    _logger.info('Fetching images: $uri');

    try {
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: _timeoutSeconds), onTimeout: () {
        throw ApiException('Request timed out after $_timeoutSeconds seconds',
            statusCode: 408);
      });

      return _handleResponse(response);
    } catch (e) {
      _logger.severe('Failed to fetch images', e);
      rethrow; // Rethrow the exception to propagate it upward
    }
  }

  /// Handles the API response and checks for various errors
  List<dynamic> _handleResponse(http.Response response) {
    _logger.info('Received response with status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data.containsKey('hits')) {
        return data['hits'];
      } else {
        throw ApiException('Invalid response structure');
      }
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized - Check your API key',
          statusCode: response.statusCode);
    } else if (response.statusCode == 429) {
      throw ApiException('Rate limit exceeded',
          statusCode: response.statusCode);
    } else {
      throw ApiException('Error fetching images: ${response.reasonPhrase}',
          statusCode: response.statusCode);
    }
  }
}
