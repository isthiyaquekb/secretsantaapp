import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'draw_state.dart';

/// Christmas season year. After Dec 25 we plan for next year.
int currentSeasonYear() {
  final n = DateTime.now();
  return (n.month == 12 && n.day > 25) ? n.year + 1 : n.year;
}

class DrawRepository {
  DrawRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static final instance = DrawRepository();

  static const _key = 'draw_state_v1';
  static const _pinHashKey = 'hr_pin_hash_v1';
  static const _pinSaltKey = 'hr_pin_salt_v1';

  final FlutterSecureStorage _storage;
  DrawState? _cache;

  bool _hasWriteFailure = false;

  /// Returns true if the last write attempt failed and data is only in memory.
  bool get hasWriteFailure => _hasWriteFailure;

  /// Optional callback invoked when a secure storage write fails.
  void Function(Object error, StackTrace stackTrace)? onWriteError;

  void resetCache() {
    _cache = null;
    _hasWriteFailure = false;
  }

  Future<DrawState> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        return _cache =
            DrawState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e, st) {
      debugPrint('DrawRepository: SecureStorage read failed, starting fresh: $e\n$st');
      /* unreadable: start fresh */
    }
    return _cache = DrawState(year: currentSeasonYear());
  }

  Future<void> save(DrawState s) async {
    _cache = s;
    try {
      await _storage.write(key: _key, value: jsonEncode(s.toJson()));
      _hasWriteFailure = false;
    } catch (e, st) {
      _hasWriteFailure = true;
      debugPrint('DrawRepository: SecureStorage write failed: $e\n$st');
      onWriteError?.call(e, st);
    }
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
    try {
      final hash = await _storage.read(key: _pinHashKey);
      return hash != null && hash.isNotEmpty;
    } catch (e, st) {
      debugPrint('DrawRepository: SecureStorage read HR pin failed: $e\n$st');
      return false;
    }
  }

  /// Stores a new 4-digit PIN with a random 16-byte salt and SHA-256 hash.
  Future<void> setHrPin(String pin) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64Encode(saltBytes);
    final hash = _hashPin(pin, salt);

    try {
      await _storage.write(key: _pinSaltKey, value: salt);
      await _storage.write(key: _pinHashKey, value: hash);
      _hasWriteFailure = false;
    } catch (e, st) {
      _hasWriteFailure = true;
      debugPrint('DrawRepository: SecureStorage write HR pin failed: $e\n$st');
      onWriteError?.call(e, st);
    }
  }

  /// Verifies entered PIN against stored salted hash.
  Future<bool> verifyHrPin(String pin) async {
    try {
      final salt = await _storage.read(key: _pinSaltKey);
      final storedHash = await _storage.read(key: _pinHashKey);
      if (salt == null || storedHash == null) return false;

      final computedHash = _hashPin(pin, salt);
      return computedHash == storedHash;
    } catch (e, st) {
      debugPrint('DrawRepository: SecureStorage verify HR pin failed: $e\n$st');
      return false;
    }
  }

  /// Clears stored PIN hash and salt.
  Future<void> clearHrPin() async {
    try {
      await _storage.delete(key: _pinHashKey);
      await _storage.delete(key: _pinSaltKey);
    } catch (e, st) {
      debugPrint('DrawRepository: SecureStorage clear HR pin failed: $e\n$st');
    }
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
