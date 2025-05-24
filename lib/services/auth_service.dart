import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/footballer_profile_model.dart';
import '../models/scout_profile_model.dart';
import '../models/club_profile_model.dart';
import '../repositories/footballer_repository.dart';
import '../repositories/scout_repository.dart';
import '../repositories/club_repository.dart';

class AuthService {
  final SupabaseClient _client;
  final FootballerRepository _footballerRepo;
  final ScoutRepository _scoutRepo;
  final ClubRepository _clubRepo;

  AuthService(this._client)
    : _footballerRepo = FootballerRepository(_client),
      _scoutRepo = ScoutRepository(_client),
      _clubRepo = ClubRepository(_client);

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      if (response.user == null) return null;

      final user = UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
      );

      // Create role-specific profile
      switch (role.toLowerCase()) {
        case 'footballer':
          await _footballerRepo.createProfile(
            FootballerProfileModel(
              userId: user.id,
              fullName: fullName,
              dateOfBirth:
                  DateTime.now(), // This will be updated in the next step
              nationality: '',
              position: '',
              preferredFoot: '',
              height: 0,
              weight: 0,
                skills: [],
              experience: '',
              club: '',
              createdAt: DateTime.now(),
            ),
          );
          break;
        case 'scout':
          await _scoutRepo.createProfile(
            ScoutProfileModel(
              userId: user.id,
              fullName: fullName,
              organization: '',
              specialization: '',
              regions: [],
              createdAt: DateTime.now(),
            ),
          );
          break;
        case 'club':
          await _clubRepo.createProfile(
            ClubProfileModel(
              userId: user.id,
              fullName: fullName,
              clubType: '',
              country: '',
              city: '',
              createdAt: DateTime.now(),
            ),
          );
          break;
      }

      return user;
    } catch (e) {
      print('Error during sign up: $e');
      return null;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      final userData =
          await _client
              .from('users')
              .select()
              .eq('id', response.user!.id)
              .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final userData =
          await _client.from('users').select().eq('id', user.id).single();

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(UserModel user) async {
    try {
      await _client.from('users').update(user.toJson()).eq('id', user.id);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
}
