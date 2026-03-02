import 'package:flutter/foundation.dart';
import 'package:sloth_budget/app/logging/app_logger.dart';
import 'package:sloth_budget/data/repositories/category_repository.dart';

class CategoryState extends ChangeNotifier {
  CategoryState(this._repo);

  final CategoryRepository _repo;

  bool _loading = false;
  String? _errorMessage;
  List<String> _categories = const [];

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  List<String> get categories => List.unmodifiable(_categories);

  Future<void>? _inFlight;

  void _setLoading(bool v) {
    if (_loading == v) return;
    _loading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    if (_errorMessage == msg) return;
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() => _setError(null);

  Future<void> load({bool force = false}) async {
    if (!force && _inFlight != null) return _inFlight!;
    _setLoading(true);
    _setError(null);

    final f = () async {
      try {
        log.i('CategoryState.load(force=$force)');
        _categories = await _repo.fetchAll();
      } catch (e, st) {
        log.e('CategoryState.load() failed', error: e, stackTrace: st);
        _setError('Failed to load categories.');
      } finally {
        _setLoading(false);
        _inFlight = null;
        notifyListeners();
      }
    }();

    _inFlight = f;
    return f;
  }

  // ─────────────────────────────────────────────
  // Mutations
  // ─────────────────────────────────────────────

  Future<bool> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _setError('Category name is required.');
      return false;
    }

    _setError(null);
    _setLoading(true);

    try {
      log.i('CategoryState.add("$trimmed")');
      await _repo.create(trimmed);
      await load(force: true);
      return true;
    } catch (e, st) {
      log.e('CategoryState.add() failed', error: e, stackTrace: st);
      _setError('Failed to add category.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reorder(List<String> ordered) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.reorder(ordered);
      _categories = List.of(ordered);
      notifyListeners();
    } catch (e, st) {
      log.e('CategoryState.reorder() failed', error: e, stackTrace: st);
      _errorMessage = 'Failed to reorder categories.';
      notifyListeners();
    }
  }

  Future<bool> rename(String from, String to) async {
    final newName = to.trim();

    if (newName.isEmpty) {
      _setError('Category name is required.');
      return false;
    }

    if (from == newName) {
      // No-op
      _setError(null);
      return true;
    }

    _setError(null);
    _setLoading(true);

    try {
      log.i('CategoryState.rename("$from" -> "$newName")');
      await _repo.rename(from, newName);
      await load(force: true);
      return true;
    } catch (e, st) {
      log.e('CategoryState.rename() failed', error: e, stackTrace: st);
      _setError('Failed to rename category.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns a user-facing message if deletion is not allowed; otherwise null.
  Future<String?> deleteWithRules(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Invalid category.';

    _setError(null);
    _setLoading(true);

    try {
      log.w('CategoryState.deleteWithRules("$trimmed")');

      final count = await _repo.usageCount(trimmed);
      if (count > 0) {
        return 'Cannot delete: category is used by $count transaction(s). Rename it or reassign those transactions first.';
      }
      if (trimmed == 'Subscriptions') {
        return '"Subscriptions" category can\'t be deleted.';
      }

      await _repo.delete(trimmed);
      await load(force: true);
      return null;
    } catch (e, st) {
      log.e('CategoryState.deleteWithRules() failed', error: e, stackTrace: st);
      _setError('Failed to delete category.');
      return 'Failed to delete category.';
    } finally {
      _setLoading(false);
    }
  }
}
