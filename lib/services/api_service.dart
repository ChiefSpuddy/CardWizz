import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

class ApiService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<http.Response> getWithRetry(String url, {int retryCount = 0}) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response;
    } on SocketException catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return getWithRetry(url, retryCount: retryCount + 1);
      }
      throw NetworkException('Network connection failed. Please check your internet connection.');
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return getWithRetry(url, retryCount: retryCount + 1);
      }
      throw NetworkException('Failed to fetch data. Please try again later.');
    }
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}
