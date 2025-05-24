import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseRepository {
  final SupabaseClient _client;

  BaseRepository(this._client);

  SupabaseClient get client => _client;

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    try {
      final response =
          await _client.from(table).select().eq('user_id', id).single();
      return response;
    } catch (e) {
      print('Error fetching from $table: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    try {
      final response = await _client.from(table).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all from $table: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> create(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      print('Error creating in $table: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await _client
              .from(table)
              .update(data)
              .eq('user_id', id)
              .select()
              .single();
      return response;
    } catch (e) {
      print('Error updating in $table: $e');
      return null;
    }
  }

  Future<bool> delete(String table, String id) async {
    try {
      await _client.from(table).delete().eq('user_id', id);
      return true;
    } catch (e) {
      print('Error deleting from $table: $e');
      return false;
    }
  }
}
