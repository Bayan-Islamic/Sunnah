import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// Persists bookmarked hadith ids locally with `shared_preferences`.
///
/// Nothing leaves the device: the bookmarks are a plain list of integer keys in
/// the app's own preferences file.
class BookmarksRepository {
  BookmarksRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Bookmarked ids, most recently added first.
  List<int> load() {
    final raw = _prefs.getStringList(AppConstants.prefBookmarks) ?? const [];
    return raw
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> save(List<int> ids) async {
    await _prefs.setStringList(
      AppConstants.prefBookmarks,
      ids.map((id) => id.toString()).toList(growable: false),
    );
  }

  /// Adds or removes [id]; returns the updated list.
  Future<List<int>> toggle(int id, List<int> current) async {
    final updated = List<int>.from(current);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.insert(0, id);
    }
    await save(updated);
    return updated;
  }
}
