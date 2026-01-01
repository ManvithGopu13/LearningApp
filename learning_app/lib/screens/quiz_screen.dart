import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import '../providers/app_provider.dart';
import '../utils/app_colors.dart';

/// Quiz screen with resume functionality
class QuizScreen extends StatefulWidget {
  final Chapter chapter;
  final Progress? progress;

  const QuizScreen({
    super.key,
    required this.chapter,
    this.progress,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late int _currentQuestionIndex;
  late List<int> _answers; // -1 means not answered
  bool _isSubmitting = false;
  bool _quizCompleted = false;
  int? _score;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  void _initializeQuiz() {
    final progress = widget.progress;
    final questionsLength = widget.chapter.quiz.questions.length;
    
    // Always ensure we have a valid answers array
    _answers = List<int>.filled(questionsLength, -1);
    
    if (progress != null && progress.quizProgress >= 0) {
      // Resume from saved progress
      _currentQuestionIndex = progress.quizProgress;
      
      // Safely copy answers if they exist and have correct length
      if (progress.quizAnswers.isNotEmpty && 
          progress.quizAnswers.length == questionsLength) {
        _answers = List<int>.from(progress.quizAnswers);
      } else if (progress.quizAnswers.isNotEmpty) {
        // If length mismatch, copy what we can
        for (int i = 0; i < progress.quizAnswers.length && i < questionsLength; i++) {
          _answers[i] = progress.quizAnswers[i];
        }
      }
      
      _quizCompleted = progress.quizCompleted;
      
      // Ensure current question index is valid
      if (_currentQuestionIndex >= questionsLength) {
        _currentQuestionIndex = 0;
      }
      
      // If quiz was completed, calculate score
      if (_quizCompleted) {
        _calculateScore();
      }
    } else {
      // Start fresh
      _currentQuestionIndex = 0;
    }
  }

  void _calculateScore() {
    if (widget.chapter.quiz.questions.isEmpty) {
      _score = 0;
      return;
    }

    int correct = 0;
    final questionsLength = widget.chapter.quiz.questions.length;
    
    for (int i = 0; i < questionsLength && i < _answers.length; i++) {
      if (i < widget.chapter.quiz.questions.length &&
          _answers[i] == widget.chapter.quiz.questions[i].correctAnswer) {
        correct++;
      }
    }
    _score = correct;
  }

  Future<void> _saveAnswer(int answer) async {
    // Safety check: ensure index is valid
    if (_currentQuestionIndex >= _answers.length || 
        _currentQuestionIndex >= widget.chapter.quiz.questions.length) {
      print('Error: Invalid question index $_currentQuestionIndex');
      return;
    }

    setState(() {
      _answers[_currentQuestionIndex] = answer;
      _isSubmitting = true;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Check if this is the last question
    final isLastQuestion = _currentQuestionIndex == widget.chapter.quiz.questions.length - 1;
    
    await provider.updateQuizProgress(
      chapterId: widget.chapter.chapterId,
      questionIndex: _currentQuestionIndex,
      answer: answer,
      completed: isLastQuestion && _answers.every((a) => a != -1),
    );

    setState(() => _isSubmitting = false);

    // Wait a bit to show the selected answer
    await Future.delayed(const Duration(milliseconds: 500));

    if (isLastQuestion && _answers.every((a) => a != -1)) {
      // Quiz completed
      setState(() {
        _quizCompleted = true;
        _calculateScore();
      });
    } else {
      // Move to next question
      setState(() {
        if (_currentQuestionIndex < widget.chapter.quiz.questions.length - 1) {
          _currentQuestionIndex++;
        }
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0 && 
        _currentQuestionIndex <= widget.chapter.quiz.questions.length) {
      setState(() => _currentQuestionIndex--);
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.chapter.quiz.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted && _score != null) {
      return _buildResultsScreen();
    }

    // Safety check: ensure we have questions
    if (widget.chapter.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapter.title)),
        body: const Center(
          child: Text('No questions available for this quiz'),
        ),
      );
    }

    // Safety check: ensure current index is valid
    if (_currentQuestionIndex >= widget.chapter.quiz.questions.length) {
      _currentQuestionIndex = 0;
    }

    final question = widget.chapter.quiz.questions[_currentQuestionIndex];
    final totalQuestions = widget.chapter.quiz.questions.length;
    
    // Safety check: ensure we have an answer for current question
    if (_currentQuestionIndex >= _answers.length) {
      // Reinitialize answers array if something went wrong
      _answers = List<int>.filled(totalQuestions, -1);
    }
    
    final currentAnswer = _answers[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '${_currentQuestionIndex + 1}/$totalQuestions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / totalQuestions,
            backgroundColor: AppColors.progressNotStarted,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.questionText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options
                  ...List.generate(question.options.length, (index) {
                    final isSelected = currentAnswer == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionCard(
                        option: question.options[index],
                        index: index,
                        isSelected: isSelected,
                        onTap: _isSubmitting ? null : () => _saveAnswer(index),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentQuestionIndex > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _previousQuestion,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                      if (_currentQuestionIndex < totalQuestions - 1 && currentAnswer != -1)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _nextQuestion,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info Text
                  Text(
                    _isSubmitting
                        ? 'Saving your answer...'
                        : 'Your progress is automatically saved',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String option,
    required int index,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final totalQuestions = widget.chapter.quiz.questions.length;
    
    // Safety check
    if (totalQuestions == 0 || _score == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Results')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unable to calculate score'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final percentage = (_score! / totalQuestions * 100).round();
    final passed = percentage >= 60; // Passing score: 60%

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: passed
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.check_circle : Icons.info,
                  size: 60,
                  color: passed ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                passed ? 'Congratulations!' : 'Good Effort!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Score
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: passed
                      ? AppColors.successGradient
                      : const LinearGradient(
                          colors: [AppColors.warning, Color(0xFFFDB462)],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (passed ? AppColors.success : AppColors.warning)
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_score / $totalQuestions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Message
              Text(
                passed
                    ? 'You\'ve successfully completed this chapter!'
                    : 'Keep practicing to improve your score!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Go back to home and refresh
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!passed)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex = 0;
                          _answers = List<int>.filled(
                            widget.chapter.quiz.questions.length,
                            -1,
                          );
                          _quizCompleted = false;
                          _score = null;
                        });
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text(
                        'Retry Quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}