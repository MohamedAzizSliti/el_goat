import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club_profile_model.dart';
import 'base_repository.dart';

class ClubRepository extends BaseRepository {
  static const String _table = 'club_profiles';

  ClubRepository(SupabaseClient client) : super(client);

  Future<ClubProfileModel?> getProfile(String userId) async {
    final data = await getById(_table, userId);
    if (data == null) return null;
    return ClubProfileModel.fromJson(data);
  }

  Future<List<ClubProfileModel>> getAllProfiles() async {
    final data = await getAll(_table);
    return data.map((json) => ClubProfileModel.fromJson(json)).toList();
  }

  Future<ClubProfileModel?> createProfile(ClubProfileModel profile) async {
    final data = await create(_table, profile.toJson());
    if (data == null) return null;
    return ClubProfileModel.fromJson(data);
  }

  Future<ClubProfileModel?> updateProfile(ClubProfileModel profile) async {
    final data = await update(_table, profile.userId, profile.toJson());
    if (data == null) return null;
    return ClubProfileModel.fromJson(data);
  }

  Future<bool> deleteProfile(String userId) async {
    return await delete(_table, userId);
  }
}
