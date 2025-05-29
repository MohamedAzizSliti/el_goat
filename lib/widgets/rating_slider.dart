import 'package:flutter/material.dart';

class RatingSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool showLabels;

  const RatingSlider({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRatingColor(value),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getRatingColor(value),
            inactiveTrackColor: Colors.grey[700],
            thumbColor: _getRatingColor(value),
            overlayColor: _getRatingColor(value).withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            trackHeight: 6,
            valueIndicatorColor: _getRatingColor(value),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            onChanged: (double newValue) {
              onChanged(newValue.round());
            },
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getRatingLabel(min),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                _getRatingLabel(max),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getRatingColor(int rating) {
    if (rating <= 3) {
      return Colors.red;
    } else if (rating <= 5) {
      return Colors.orange;
    } else if (rating <= 7) {
      return Colors.yellow[700]!;
    } else if (rating <= 8) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }

  String _getRatingLabel(int rating) {
    if (rating <= 3) {
      return 'Poor';
    } else if (rating <= 5) {
      return 'Average';
    } else if (rating <= 7) {
      return 'Good';
    } else if (rating <= 8) {
      return 'Very Good';
    } else {
      return 'Excellent';
    }
  }
}

class RatingDisplay extends StatelessWidget {
  final String label;
  final double value;
  final bool showValue;
  final Color? color;

  const RatingDisplay({
    Key? key,
    required this.label,
    required this.value,
    this.showValue = true,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? _getRatingColor(value);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showValue)
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: displayColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 10).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating <= 3) {
      return Colors.red;
    } else if (rating <= 5) {
      return Colors.orange;
    } else if (rating <= 7) {
      return Colors.yellow[700]!;
    } else if (rating <= 8) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
}

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const RatingStars({
    Key? key,
    required this.rating,
    this.maxStars = 5,
    this.size = 20,
    this.activeColor = Colors.yellow,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starRating = (rating / 2).clamp(0.0, 5.0); // Convert 10-point to 5-star
        final isActive = index < starRating.floor();
        final isHalf = index == starRating.floor() && starRating % 1 != 0;

        return Icon(
          isHalf ? Icons.star_half : (isActive ? Icons.star : Icons.star_border),
          color: isActive || isHalf ? activeColor : inactiveColor,
          size: size,
        );
      }),
    );
  }
}
