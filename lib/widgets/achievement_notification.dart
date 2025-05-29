import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AchievementNotification extends StatelessWidget {
  final String title;
  final String description;
  final String? iconPath;
  final VoidCallback? onTap;

  const AchievementNotification({
    Key? key,
    required this.title,
    required this.description,
    this.iconPath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (iconPath != null)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(iconPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slide(
          begin: const Offset(0, -1),
          end: const Offset(0, 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
        )
        .fade(
          begin: 0.0,
          end: 1.0,
          duration: const Duration(milliseconds: 300),
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
        );
  }
} 