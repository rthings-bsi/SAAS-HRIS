import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'overtime_models.dart';

class OvertimeDraftService {
  static String _keyForUser(int userId) => 'overtime_drafts_$userId';

  Future<List<OvertimeDraftModel>> loadDrafts(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForUser(userId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final drafts = <OvertimeDraftModel>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          drafts.add(OvertimeDraftModel.fromJson(item));
        } else if (item is Map) {
          drafts.add(
            OvertimeDraftModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return drafts;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDraft(int userId, OvertimeDraftModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadDrafts(userId);
    final updated = [
      draft,
      ...current.where((d) => d.id != draft.id),
    ].take(10).toList();
    await prefs.setString(
      _keyForUser(userId),
      jsonEncode(updated.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> deleteDraft(int userId, String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadDrafts(userId);
    final filtered = current.where((d) => d.id != draftId).toList();
    await prefs.setString(
      _keyForUser(userId),
      jsonEncode(filtered.map((d) => d.toJson()).toList()),
    );
  }
}
