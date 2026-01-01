import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/progress.dart';
import '../utils/app_colors.dart';

/// Card widget to display chapter information
class ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final Progress? progress;
  final VoidCallback onTap;

  const ChapterCard({
    super.key,
    required this.chapter,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress?.hasProgress ?? false;
    final progressPercentage = progress?.getProgressPercentage() ?? 0;
    final isCompleted = progress?.chapterCompleted ?? false;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chapter Number Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? AppColors.successGradient
                    : hasProgress
                        ? AppColors.primaryGradient
                        : const LinearGradient(
                            colors: [AppColors.surfaceLight, Colors.white],
                          ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (hasProgress)
                    BoxShadow(
                      color: (isCompleted ? AppColors.success : AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 28,
                      )
                    : Text(
                        '${chapter.order}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: hasProgress ? Colors.white : AppColors.textHint,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Chapter Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chapter.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar
                  if (hasProgress && !isCompleted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPercentage / 100,
                              backgroundColor: AppColors.progressNotStarted,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.progressInProgress,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${progressPercentage.toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Duration and Quiz Info
                  if (!hasProgress || isCompleted) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chapter.formattedDuration,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.quiz_outlined,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${chapter.quiz.questions.length} Qs',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Arrow Icon
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}