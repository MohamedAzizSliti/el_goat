import 'package:supabase_flutter/supabase_flutter.dart';

class RatingsService {
  final supabase = Supabase.instance.client;

  // Add a rating to a footballer
  Future<void> addFootballerRating(String footballerId, double rating, String comment) async {
    await supabase.from('ratings').insert({
      'user_id': supabase.auth.currentUser?.id,
      'footballer_id': footballerId,
      'rating': rating,
      'comment': comment,
    });
  }

  // Get all ratings for a specific footballer
  Future<List<Map<String, dynamic>>> getFootballerRatings(String footballerId) async {
    final response = await supabase
        .from('ratings')
        .select('*')
        .eq('footballer_id', footballerId);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get average rating for a footballer
  Future<double> getAverageRating(String footballerId) async {
    final response = await supabase
        .from('ratings')
        .select('rating')
        .eq('footballer_id', footballerId);
    final ratings = List<Map<String, dynamic>>.from(response);
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold(0.0, (sum, r) => sum + (r['rating'] as num).toDouble());
    return total / ratings.length;
  }
}
