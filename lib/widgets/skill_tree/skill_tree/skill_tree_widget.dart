import 'package:el_goat/models/skill_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkillTreeWidget extends StatefulWidget {
  final List<SkillCategory> categories;
  final Function(String) onSkillTap;

  const SkillTreeWidget({
    Key? key,
    required this.categories,
    required this.onSkillTap,
  }) : super(key: key);

  @override
  State<SkillTreeWidget> createState() => _SkillTreeWidgetState();
}

class _SkillTreeWidgetState extends State<SkillTreeWidget> {
  int _selectedCategoryIndex = 0;
  final _pageController = PageController();
  // Cache for skill node widgets
  final Map<String, Widget> _nodeCache = {};
  // Cache for connection line painters
  final Map<String, CustomPainter> _lineCache = {};

  @override
  void didUpdateWidget(SkillTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear caches if categories change
    if (oldWidget.categories != widget.categories) {
      _nodeCache.clear();
      _lineCache.clear();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoryTabs(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.categories.length,
            onPageChanged: (index) {
              setState(() => _selectedCategoryIndex = index);
            },
            itemBuilder: (context, index) {
              return _buildSkillTree(widget.categories[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryIndex = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.categories[index].name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate(target: isSelected ? 1 : 0)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
              )
              .fadeIn(),
          );
        },
      ),
    );
  }

  Widget _buildSkillTree(SkillCategory category) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: category.skills.length,
      itemBuilder: (context, index) {
        final skill = category.skills[index];
        final isUnlocked = skill.currentLevel > 1;
        final nextMilestone = (skill.currentLevel ~/ 10 + 1) * 10;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => widget.onSkillTap(skill.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [Colors.blue.shade700, Colors.blue.shade900]
                      : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isUnlocked
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getSkillIcon(skill.name),
                          color: isUnlocked ? Colors.white : Colors.grey.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              skill.name,
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              skill.description,
                              style: TextStyle(
                                color: isUnlocked
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? Colors.green.shade600
                              : Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Lvl ${skill.currentLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress to Level $nextMilestone',
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          Text(
                            '${(skill.progress * 100).toInt()}%',
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.white70
                                  : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: skill.progress,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(
                            isUnlocked
                                ? Colors.green.shade400
                                : Colors.grey.shade600,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  if (skill.attributes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skill.attributes.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ).animate()
          .fadeIn(delay: Duration(milliseconds: index * 100))
          .slideX(begin: 0.2, end: 0);
      },
    );
  }

  IconData _getSkillIcon(String skillName) {
    switch (skillName.toLowerCase()) {
      case 'power shot':
        return Icons.sports_soccer;
      case 'finesse shot':
        return Icons.sports_soccer;
      case 'ball control':
        return Icons.control_camera;
      case 'speed dribbling':
        return Icons.speed;
      case 'through pass':
        return Icons.timeline;
      case 'long pass':
        return Icons.swap_horiz;
      case 'stamina':
        return Icons.battery_charging_full;
      case 'sprint speed':
        return Icons.directions_run;
      case 'positioning':
        return Icons.place;
      case 'game reading':
        return Icons.psychology;
      default:
        return Icons.star;
    }
  }

  Widget _buildSkillNode(Skill skill, double progress) {
    final cacheKey = '${skill.id}_$progress';
    if (_nodeCache.containsKey(cacheKey)) {
      return _nodeCache[cacheKey]!;
    }

    final node = GestureDetector(
      onTap: () => widget.onSkillTap(skill.id),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: progress >= 1.0 ? Colors.green : Colors.grey[800],
          border: Border.all(
            color: progress > 0 ? Colors.amber : Colors.grey,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (progress >= 1.0 ? Colors.green : Colors.amber)
                  .withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              skill.icon ?? Icons.star,
              color: progress >= 1.0 ? Colors.white : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              skill.name,
              style: TextStyle(
                color: progress >= 1.0 ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate()
        .scale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        )
        .fade(
          duration: const Duration(milliseconds: 200),
        ),
    );

    _nodeCache[cacheKey] = node;
    return node;
  }

  CustomPainter _buildConnectionLine(Offset start, Offset end, double progress) {
    final cacheKey = '${start.toString()}_${end.toString()}_$progress';
    if (_lineCache.containsKey(cacheKey)) {
      return _lineCache[cacheKey]!;
    }

    final painter = SkillConnectionPainter(
      start: start,
      end: end,
      progress: progress,
      color: progress >= 1.0 ? Colors.green : Colors.amber,
    );

    _lineCache[cacheKey] = painter;
    return painter;
  }
}

class SkillConnectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final Color color;

  SkillConnectionPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final pathMetrics = path.computeMetrics().first;
    final pathProgress = pathMetrics.extractPath(
      0,
      pathMetrics.length * progress,
    );

    canvas.drawPath(pathProgress, paint);

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(pathProgress, glowPaint);
  }

  @override
  bool shouldRepaint(SkillConnectionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.start != start ||
           oldDelegate.end != end ||
           oldDelegate.color != color;
  }
} 