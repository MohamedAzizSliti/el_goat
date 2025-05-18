import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final supabase = Supabase.instance.client;

  Future<void> addFavorite(String footballerId) async {
    await supabase.from('favorites').insert({
      'footballer_id': footballerId,
      'user_id': supabase.auth.currentUser?.id,
    });
  }

  Future<void> removeFavorite(String favoriteId) async {
    await supabase.from('favorites').delete().eq('id', favoriteId);
  }

  Future<List<Map<String, dynamic>>> getMyFavorites() async {
    final data = await supabase
        .from('favorites')
        .select('*, footballer_profiles(*)')
        .eq('user_id', supabase.auth.currentUser!.id);

    return List<Map<String, dynamic>>.from(data);
  }
}
