import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/chapter.dart';
import '../models/progress.dart';

/// API Service to handle all backend communication
class ApiService {
  // Base URL - change this to your backend URL
  // For local development: http://localhost:8080
  // For Android emulator: http://10.0.2.2:8080
  // For iOS simulator: http://localhost:8080
  static const String baseUrl = 'http://172.31.112.1:8080/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Helper method to get headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Helper method to handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'An error occurred');
    }
  }

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  /// Login or register user
  Future<User> login(String userId, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _getHeaders(),
        body: json.encode({
          'userId': userId,
          'name': name,
        }),
      );

      final data = _handleResponse(response);
      return User.fromJson(data['user']);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // ============================================================================
  // CHAPTER ENDPOINTS
  // ============================================================================

  /// Get all chapters
  Future<List<Chapter>> getChapters() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chapters'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      final List<dynamic> chaptersJson = data['data'];
      return chaptersJson.map((json) => Chapter.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch chapters: $e');
    }
  }

  /// Get a specific chapter by ID
  Future<Chapter> getChapterById(String chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chapters/$chapterId'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return Chapter.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to fetch chapter: $e');
    }
  }

  // ============================================================================
  // PROGRESS ENDPOINTS
  // ============================================================================

  /// Get all progress for a user
  Future<List<Progress>> getUserProgress(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/$userId'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      final List<dynamic>? progressJson = data['progress'];
      
      // Handle null or empty response
      if (progressJson == null) {
        return [];
      }
      
      return progressJson.map((json) => Progress.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user progress: $e');
      // Return empty list instead of throwing to allow app to continue
      return [];
    }
  }

  /// Get progress for a specific chapter
  Future<Progress> getChapterProgress(String userId, String chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/$userId/$chapterId'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return Progress.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to fetch chapter progress: $e');
    }
  }

  /// Update video progress
  Future<void> updateVideoProgress({
    required String userId,
    required String chapterId,
    required int progress,
    required bool completed,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/video'),
        headers: _getHeaders(),
        body: json.encode({
          'userId': userId,
          'chapterId': chapterId,
          'progress': progress,
          'completed': completed,
        }),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update video progress: $e');
    }
  }

  /// Update quiz progress
  Future<void> updateQuizProgress({
    required String userId,
    required String chapterId,
    required int questionIndex,
    required int answer,
    required bool completed,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/quiz'),
        headers: _getHeaders(),
        body: json.encode({
          'userId': userId,
          'chapterId': chapterId,
          'questionIndex': questionIndex,
          'answer': answer,
          'completed': completed,
        }),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update quiz progress: $e');
    }
  }

  /// Reset all progress for a user (useful for testing)
  Future<void> resetProgress(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/progress/$userId/reset'),
        headers: _getHeaders(),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to reset progress: $e');
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}