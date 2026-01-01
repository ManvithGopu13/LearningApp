import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Main app provider managing global state
class AppProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // State variables
  User? _currentUser;
  List<Chapter> _chapters = [];
  Map<String, Progress> _progressMap = {}; // chapterId -> Progress
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  List<Chapter> get chapters => _chapters;
  Map<String, Progress> get progressMap => _progressMap;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  /// Initialize app - check for saved user
  Future<void> initialize() async {
    setLoading(true);
    try {
      final savedUser = await _storageService.getUser();
      if (savedUser != null) {
        _currentUser = savedUser;
        await loadChapters();
        await loadUserProgress();
      }
    } catch (e) {
      setError('Failed to initialize app: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Login user
  Future<bool> login(String userId, String name) async {
    setLoading(true);
    setError(null);
    
    try {
      // Validate input
      if (userId.trim().isEmpty) {
        setError('User ID cannot be empty');
        return false;
      }

      // Call API
      final user = await _apiService.login(userId, name.isEmpty ? userId : name);
      
      // Save user locally
      await _storageService.saveUser(user);
      
      // Update state
      _currentUser = user;
      
      // Load chapters and progress
      await loadChapters();
      await loadUserProgress();
      
      notifyListeners();
      return true;
    } catch (e) {
      setError('Login failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _storageService.clearUser();
    _currentUser = null;
    _chapters = [];
    _progressMap = {};
    notifyListeners();
  }

  /// Load all chapters
  Future<void> loadChapters() async {
    try {
      _chapters = await _apiService.getChapters();
      notifyListeners();
    } catch (e) {
      setError('Failed to load chapters: $e');
    }
  }

  /// Load user progress for all chapters
  Future<void> loadUserProgress() async {
    if (_currentUser == null) return;

    try {
      final progressList = await _apiService.getUserProgress(_currentUser!.userId);
      
      // Convert list to map for easy lookup
      _progressMap = {};
      for (var progress in progressList) {
        _progressMap[progress.chapterId] = progress;
      }
      
      notifyListeners();
    } catch (e) {
      setError('Failed to load progress: $e');
    }
  }

  /// Get progress for a specific chapter
  Progress? getProgressForChapter(String chapterId) {
    return _progressMap[chapterId];
  }

  /// Get the most recently accessed chapter (for "Continue" card)
  Chapter? getContinueChapter() {
    if (_progressMap.isEmpty) return null;

    // Find the most recently accessed progress
    Progress? mostRecent;
    for (var progress in _progressMap.values) {
      if (!progress.chapterCompleted) {
        if (mostRecent == null || 
            progress.lastAccessedAt.isAfter(mostRecent.lastAccessedAt)) {
          mostRecent = progress;
        }
      }
    }

    if (mostRecent == null) return null;

    // Find the corresponding chapter
    return _chapters.firstWhere(
      (chapter) => chapter.chapterId == mostRecent!.chapterId,
      orElse: () => _chapters.first,
    );
  }

  /// Update video progress
  Future<void> updateVideoProgress({
    required String chapterId,
    required int progress,
    required bool completed,
  }) async {
    if (_currentUser == null) return;

    try {
      await _apiService.updateVideoProgress(
        userId: _currentUser!.userId,
        chapterId: chapterId,
        progress: progress,
        completed: completed,
      );

      // Update local state
      final existingProgress = _progressMap[chapterId];
      if (existingProgress != null) {
        _progressMap[chapterId] = existingProgress.copyWith(
          videoProgress: progress,
          videoCompleted: completed,
          lastAccessedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        _progressMap[chapterId] = Progress(
          userId: _currentUser!.userId,
          chapterId: chapterId,
          videoProgress: progress,
          videoCompleted: completed,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error updating video progress: $e');
    }
  }

  /// Update quiz progress
  Future<void> updateQuizProgress({
    required String chapterId,
    required int questionIndex,
    required int answer,
    required bool completed,
  }) async {
    if (_currentUser == null) return;

    try {
      await _apiService.updateQuizProgress(
        userId: _currentUser!.userId,
        chapterId: chapterId,
        questionIndex: questionIndex,
        answer: answer,
        completed: completed,
      );

      // Reload progress to get updated data from server
      await loadUserProgress();
    } catch (e) {
      print('Error updating quiz progress: $e');
    }
  }

  /// Reset all progress
  Future<void> resetProgress() async {
    if (_currentUser == null) return;

    setLoading(true);
    try {
      await _apiService.resetProgress(_currentUser!.userId);
      _progressMap = {};
      notifyListeners();
    } catch (e) {
      setError('Failed to reset progress: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Set loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void setError(String? message) {
    _error = message;
    if (message != null) {
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}