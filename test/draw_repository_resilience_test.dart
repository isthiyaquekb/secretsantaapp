import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secretsantaapp/core/data/draw_repository.dart';
import 'package:secretsantaapp/core/data/draw_state.dart';

class FailingSecureStorage extends FlutterSecureStorage {
  const FailingSecureStorage({this.failOnWrite = true, this.failOnRead = false});

  final bool failOnWrite;
  final bool failOnRead;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failOnWrite) {
      throw PlatformException(
        code: '-34018',
        message: "A required entitlement isn't present.",
      );
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failOnRead) {
      throw PlatformException(
        code: '-34018',
        message: "A required entitlement isn't present.",
      );
    }
    return null;
  }
}

void main() {
  group('DrawRepository Storage Resilience', () {
    test(
        'write failure keeps data in memory cache, sets hasWriteFailure, and does not throw',
        () async {
      final failingStorage = const FailingSecureStorage(failOnWrite: true);
      final repo = DrawRepository(storage: failingStorage);

      Object? capturedError;
      repo.onWriteError = (error, stackTrace) {
        capturedError = error;
      };

      final newState = DrawState(
        year: 2026,
        participants: ['Alice', 'Bob', 'Charlie'],
      );

      // Must complete without throwing any exception
      await expectLater(repo.save(newState), completes);

      // Verify in-memory state updated
      final loadedState = await repo.load();
      expect(loadedState.participants, equals(['Alice', 'Bob', 'Charlie']));
      expect(loadedState.year, equals(2026));

      // Verify failure tracking
      expect(repo.hasWriteFailure, isTrue);
      expect(capturedError, isA<PlatformException>());
      expect((capturedError as PlatformException).code, equals('-34018'));
    });

    test(
        'read failure returns fresh empty DrawState and does not throw',
        () async {
      final failingStorage = const FailingSecureStorage(failOnRead: true);
      final repo = DrawRepository(storage: failingStorage);

      DrawState? loadedState;
      await expectLater(
        () async => loadedState = await repo.load(),
        returnsNormally,
      );

      expect(loadedState, isNotNull);
      expect(loadedState!.participants, isEmpty);
      expect(loadedState!.pairings, isEmpty);
    });
  });
}
