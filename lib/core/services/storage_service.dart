import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secretsantaapp/core/employee_pair.dart';

class StorageService {
  static const String _keyParticipants = 'secretsanta_participants';
  static const String _keyPairings = 'secretsanta_pairings';
  static const String _keyHrPin = 'secretsanta_hr_pin';
  static const String defaultHrPin = '1234';

  static Future<List<String>> loadParticipants() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyParticipants) ?? [];
  }

  static Future<void> saveParticipants(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyParticipants, list);
  }

  static Future<List<EmployeePair>> loadPairings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyPairings);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => EmployeePair.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePairings(List<EmployeePair> pairings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(pairings.map((p) => p.toJson()).toList());
    await prefs.setString(_keyPairings, jsonStr);
  }

  static Future<void> clearPairings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPairings);
  }

  static Future<String> getHrPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHrPin) ?? defaultHrPin;
  }

  static Future<void> setHrPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHrPin, pin);
  }
}

