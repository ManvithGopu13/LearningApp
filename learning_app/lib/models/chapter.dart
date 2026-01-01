/// Question model representing a quiz question
class Question {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswer;

  Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      questionText: json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
}

/// Quiz model representing a chapter quiz
class Quiz {
  final List<Question> questions;

  Quiz({required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      questions: (json['questions'] as List?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

/// Chapter model representing a learning chapter
class Chapter {
  final String id;
  final String chapterId;
  final String title;
  final String description;
  final String videoUrl;
  final int duration; // in seconds
  final Quiz quiz;
  final int order;

  Chapter({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.quiz,
    required this.order,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? '',
      chapterId: json['chapterId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      duration: json['duration'] ?? 0,
      quiz: Quiz.fromJson(json['quiz'] ?? {}),
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapterId': chapterId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
      'quiz': quiz.toJson(),
      'order': order,
    };
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Chapter(chapterId: $chapterId, title: $title, order: $order)';
  }
}