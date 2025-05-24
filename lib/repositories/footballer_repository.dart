import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/footballer_profile_model.dart';
import 'base_repository.dart';

class FootballerRepository extends BaseRepository {
  static const String _table = 'footballer_profiles';

  FootballerRepository(SupabaseClient client) : super(client);

  Future<FootballerProfileModel?> getProfile(String userId) async {
    final data = await getById(_table, userId);
    if (data == null) return null;
    return FootballerProfileModel.fromJson(data);
  }

  Future<List<FootballerProfileModel>> getAllProfiles() async {
    final data = await getAll(_table);
    return data.map((json) => FootballerProfileModel.fromJson(json)).toList();
  }

  Future<FootballerProfileModel?> createProfile(
    FootballerProfileModel profile,
  ) async {
    try {
      final data =
          await client
              .from(_table)
              .upsert(profile.toJson(), onConflict: 'user_id')
              .select()
              .single();
      return FootballerProfileModel.fromJson(data);
    } catch (e) {
      print('Error creating profile: $e');
      return null;
    }
  }

  Future<FootballerProfileModel?> updateProfile(
    FootballerProfileModel profile,
  ) async {
    final data = await update(_table, profile.userId, profile.toJson());
    if (data == null) return null;
    return FootballerProfileModel.fromJson(data);
  }

  Future<bool> deleteProfile(String userId) async {
    return await delete(_table, userId);
  }
}
