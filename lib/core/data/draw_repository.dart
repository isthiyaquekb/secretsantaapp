import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'draw_state.dart';

/// Christmas season year. After Dec 25 we plan for next year.
int currentSeasonYear() {
  final n = DateTime.now();
  return (n.month == 12 && n.day > 25) ? n.year + 1 : n.year;
}

class DrawRepository {
  DrawRepository._();
  static final instance = DrawRepository._();

  static const _key = 'draw_state_v1';
  static const _pinHashKey = 'hr_pin_hash_v1';
  static const _pinSaltKey = 'hr_pin_salt_v1';

  final _storage = const FlutterSecureStorage();
  DrawState? _cache;

  void resetCache() {
    _cache = null;
  }

  Future<DrawState> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        return _cache =
            DrawState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      /* unreadable: start fresh */
    }
    return _cache = DrawState(year: currentSeasonYear());
  }

  Future<void> save(DrawState s) async {
    _cache = s;
    await _storage.write(key: _key, value: jsonEncode(s.toJson()));
  }

  Future<void> markRevealed(String name) async {
    final s = await load();
    await save(s.copyWith(revealed: {...s.revealed, name}));
  }

  /// HR "Reset draw": keep the names, clear pairings and progress.
  Future<void> resetDraw() async {
    final s = await load();
    await save(DrawState(year: s.year, participants: s.participants));
  }

  /// Completely resets draw and clears the HR PIN (for forgot-PIN recovery).
  Future<void> resetDrawAndPin() async {
    await resetDraw();
    await clearHrPin();
  }

  // --- HR Master PIN (Salted SHA-256 in FlutterSecureStorage) ---

  /// Returns true if an HR PIN has been configured.
  Future<bool> hasHrPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Stores a new 4-digit PIN with a random 16-byte salt and SHA-256 hash.
  Future<void> setHrPin(String pin) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64Encode(saltBytes);
    final hash = _hashPin(pin, salt);

    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  /// Verifies entered PIN against stored salted hash.
  Future<bool> verifyHrPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) return false;

    final computedHash = _hashPin(pin, salt);
    return computedHash == storedHash;
  }

  /// Clears stored PIN hash and salt.
  Future<void> clearHrPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
