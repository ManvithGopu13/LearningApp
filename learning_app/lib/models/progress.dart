/// Progress model representing user's learning progress for a chapter
class Progress {
  final String id;
  final String userId;
  final String chapterId;
  final int videoProgress; // in seconds
  final bool videoCompleted;
  final int quizProgress; // current question index
  final List<int> quizAnswers; // user's answers (-1 = not answered)
  final bool quizCompleted;
  final bool chapterCompleted;
  final DateTime lastAccessedAt;
  final DateTime updatedAt;

  Progress({
    this.id = '',
    required this.userId,
    required this.chapterId,
    this.videoProgress = 0,
    this.videoCompleted = false,
    this.quizProgress = 0,
    this.quizAnswers = const [],
    this.quizCompleted = false,
    this.chapterCompleted = false,
    DateTime? lastAccessedAt,
    DateTime? updatedAt,
  })  : lastAccessedAt = lastAccessedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      chapterId: json['chapterId'] ?? '',
      videoProgress: json['videoProgress'] ?? 0,
      videoCompleted: json['videoCompleted'] ?? false,
      quizProgress: json['quizProgress'] ?? 0,
      quizAnswers: List<int>.from(json['quizAnswers'] ?? []),
      quizCompleted: json['quizCompleted'] ?? false,
      chapterCompleted: json['chapterCompleted'] ?? false,
      lastAccessedAt: DateTime.parse(
          json['lastAccessedAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'chapterId': chapterId,
      'videoProgress': videoProgress,
      'videoCompleted': videoCompleted,
      'quizProgress': quizProgress,
      'quizAnswers': quizAnswers,
      'quizCompleted': quizCompleted,
      'chapterCompleted': chapterCompleted,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Calculate progress percentage for the chapter (0-100)
  double getProgressPercentage() {
    // Video is 50% of progress, Quiz is 50%
    double videoPercent = videoCompleted ? 50.0 : 0.0;
    double quizPercent = quizCompleted ? 50.0 : 0.0;
    return videoPercent + quizPercent;
  }

  /// Check if any progress has been made
  bool get hasProgress {
    return videoProgress > 0 || quizProgress > 0 || videoCompleted || quizCompleted;
  }

  /// Get current status text
  String get statusText {
    if (chapterCompleted) {
      return 'Completed';
    } else if (quizProgress > 0 || quizCompleted) {
      return 'Quiz in progress';
    } else if (videoProgress > 0 || videoCompleted) {
      return 'Video in progress';
    } else {
      return 'Not started';
    }
  }

  Progress copyWith({
    String? id,
    String? userId,
    String? chapterId,
    int? videoProgress,
    bool? videoCompleted,
    int? quizProgress,
    List<int>? quizAnswers,
    bool? quizCompleted,
    bool? chapterCompleted,
    DateTime? lastAccessedAt,
    DateTime? updatedAt,
  }) {
    return Progress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chapterId: chapterId ?? this.chapterId,
      videoProgress: videoProgress ?? this.videoProgress,
      videoCompleted: videoCompleted ?? this.videoCompleted,
      quizProgress: quizProgress ?? this.quizProgress,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      quizCompleted: quizCompleted ?? this.quizCompleted,
      chapterCompleted: chapterCompleted ?? this.chapterCompleted,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Progress(chapterId: $chapterId, videoProgress: $videoProgress, quizProgress: $quizProgress, completed: $chapterCompleted)';
  }
}