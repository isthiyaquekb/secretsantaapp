import 'dart:math';
import 'package:secretsantaapp/core/employee_pair.dart';

class SecretSantaDrawService {
  SecretSantaDrawService._();

  /// Generates a single-cycle Secret Santa pairing using Sattolo's algorithm.
  /// 
  /// Properties guaranteed:
  /// 1. Exactly one cycle of length N containing all participants.
  /// 2. No self-pairing (nobody can draw themselves).
  /// 3. Everyone gives to exactly one person, and receives from exactly one person.
  /// 4. The last person is guaranteed a valid recipient, completing the cycle.
  static List<EmployeePair> generatePairings(
    List<String> participants, [
    Random? random,
  ]) {
    final cleanList = participants
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (cleanList.length < 3) {
      throw ArgumentError(
        'A minimum of 3 participants is required for Secret Santa.',
      );
    }

    // Work on a copy of the list
    final shuffled = List<String>.from(cleanList);
    final rng = random ?? Random();

    // Sattolo's algorithm:
    // For i from n - 1 down to 1:
    //   j = uniform random integer strictly less than i (0 <= j < i)
    //   swap shuffled[i] and shuffled[j]
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = rng.nextInt(i); // Strictly 0 <= j < i
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    // Form pairings in the cycle:
    // shuffled[0] -> shuffled[1] -> ... -> shuffled[n-1] -> shuffled[0]
    final List<EmployeePair> pairs = [];
    for (int i = 0; i < shuffled.length; i++) {
      final picker = shuffled[i];
      final picked = shuffled[(i + 1) % shuffled.length];
      pairs.add(EmployeePair(picker: picker, picked: picked));
    }

    return pairs;
  }
}

