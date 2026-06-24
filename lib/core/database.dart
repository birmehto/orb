import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/clip_item.dart';
import 'models/bubble_settings.dart';

class Database {
  static Database? _instance;
  late SharedPreferences _prefs;

  Database._();

  static Future<Database> getInstance() async {
    if (_instance == null) {
      _instance = Database._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  static const _clipsKey = 'orb_clips';
  static const _settingsKey = 'orb_bubble_settings';
  static const maxClips = 100;

  List<ClipItem> getClips() {
    final json = _prefs.getString(_clipsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => ClipItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addClip(String text) async {
    final clips = getClips();
    clips.removeWhere((c) => c.text == text);
    clips.insert(0, ClipItem(text: text, timestamp: DateTime.now()));
    if (clips.length > maxClips) clips.removeRange(maxClips, clips.length);
    await _prefs.setString(_clipsKey, jsonEncode(clips.map((c) => c.toJson()).toList()));
  }

  Future<void> toggleFavorite(String text) async {
    final clips = getClips();
    final index = clips.indexWhere((c) => c.text == text);
    if (index == -1) return;
    clips[index] = clips[index].copyWith(isFavorite: !clips[index].isFavorite);
    await _prefs.setString(_clipsKey, jsonEncode(clips.map((c) => c.toJson()).toList()));
  }

  Future<void> deleteClip(String text) async {
    final clips = getClips();
    clips.removeWhere((c) => c.text == text);
    await _prefs.setString(_clipsKey, jsonEncode(clips.map((c) => c.toJson()).toList()));
  }

  BubbleSettings getSettings() {
    final json = _prefs.getString(_settingsKey);
    if (json == null) return const BubbleSettings();
    return BubbleSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveSettings(BubbleSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
