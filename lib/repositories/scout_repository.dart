import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scout_profile_model.dart';
import 'base_repository.dart';

class ScoutRepository extends BaseRepository {
  static const String _table = 'scout_profiles';

  ScoutRepository(SupabaseClient client) : super(client);

  Future<ScoutProfileModel?> getProfile(String userId) async {
    final data = await getById(_table, userId);
    if (data == null) return null;
    return ScoutProfileModel.fromJson(data);
  }

  Future<List<ScoutProfileModel>> getAllProfiles() async {
    final data = await getAll(_table);
    return data.map((json) => ScoutProfileModel.fromJson(json)).toList();
  }

  Future<ScoutProfileModel?> createProfile(ScoutProfileModel profile) async {
    final data = await create(_table, profile.toJson());
    if (data == null) return null;
    return ScoutProfileModel.fromJson(data);
  }

  Future<ScoutProfileModel?> updateProfile(ScoutProfileModel profile) async {
    final data = await update(_table, profile.userId, profile.toJson());
    if (data == null) return null;
    return ScoutProfileModel.fromJson(data);
  }

  Future<bool> deleteProfile(String userId) async {
    return await delete(_table, userId);
  }
}
