import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:async';
import '../models/chapter.dart';
import '../models/progress.dart';
import '../providers/app_provider.dart';
import '../utils/app_colors.dart';
import 'quiz_screen.dart';

/// Video player screen with resume functionality
class VideoPlayerScreen extends StatefulWidget {
  final Chapter chapter;
  final Progress? progress;

  const VideoPlayerScreen({
    super.key,
    required this.chapter,
    this.progress,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  Timer? _progressTimer;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _videoCompleted = false;
  int _lastSavedPosition = 0;
  
  // Store provider reference to avoid accessing it in dispose
  AppProvider? _appProvider;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store provider reference early to use in dispose safely
    _appProvider = Provider.of<AppProvider>(context, listen: false);
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.chapter.videoUrl),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade400,
        ),
      );

      // Resume from saved position
      if (widget.progress != null && widget.progress!.videoProgress > 0) {
        _videoPlayerController.seekTo(
          Duration(seconds: widget.progress!.videoProgress),
        );
        _lastSavedPosition = widget.progress!.videoProgress;
      }

      // Listen for video completion
      _videoPlayerController.addListener(_videoListener);

      // Start progress tracking
      _startProgressTracking();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _videoListener() {
    // Check if video is completed
    if (_videoPlayerController.value.position >=
        _videoPlayerController.value.duration) {
      if (!_videoCompleted) {
        _videoCompleted = true;
        _saveProgress(completed: true);
      }
    }
  }

  void _startProgressTracking() {
    // Save progress every 5 seconds
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_videoPlayerController.value.isPlaying) {
        _saveProgress();
      }
    });
  }

  Future<void> _saveProgress({bool completed = false}) async {
    if (!_isInitialized || !mounted || _appProvider == null) return;

    final currentPosition = _videoPlayerController.value.position.inSeconds;

    // Only save if position changed significantly (at least 3 seconds)
    if ((currentPosition - _lastSavedPosition).abs() < 3 && !completed) {
      return;
    }

    _lastSavedPosition = currentPosition;

    // Use stored provider reference instead of accessing from context
    await _appProvider!.updateVideoProgress(
      chapterId: widget.chapter.chapterId,
      progress: currentPosition,
      completed: completed || _videoCompleted,
    );

    print('Progress saved: $currentPosition seconds, completed: ${completed || _videoCompleted}');
  }

  void _navigateToQuiz() {
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          chapter: widget.chapter,
          progress: _appProvider?.getProgressForChapter(widget.chapter.chapterId),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoPlayerController.removeListener(_videoListener);
    
    // Save progress one last time before disposing
    if (_isInitialized && _appProvider != null) {
      final currentPosition = _videoPlayerController.value.position.inSeconds;
      _appProvider!.updateVideoProgress(
        chapterId: widget.chapter.chapterId,
        progress: currentPosition,
        completed: _videoCompleted,
      );
    }
    
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.chapter.title,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Video Player Section
                      if (_hasError)
                        Container(
                          height: 300,
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to load video',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Go Back'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!_isInitialized)
                        Container(
                          height: 300,
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        )
                      else
                        AspectRatio(
                          aspectRatio: _videoPlayerController.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        ),

                      // Content Section
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Chapter Info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.chapter.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.chapter.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.play_circle_outline,
                                          size: 18,
                                          color: AppColors.textHint,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.chapter.formattedDuration,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons.quiz_outlined,
                                          size: 18,
                                          color: AppColors.textHint,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${widget.chapter.quiz.questions.length} Questions',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Divider(height: 1),

                              // Action Buttons
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Video Completed Badge
                                    if (widget.progress?.videoCompleted == true)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: AppColors.success,
                                              size: 20,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Video completed',
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Continue to Quiz Button
                                    ElevatedButton.icon(
                                      onPressed: _navigateToQuiz,
                                      icon: const Icon(Icons.arrow_forward, size: 20),
                                      label: const Text(
                                        'Continue to Quiz',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Auto-save Info
                                    Text(
                                      'Progress auto-saved',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}