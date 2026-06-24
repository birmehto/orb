import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/clip_item.dart';
import 'models/note_item.dart';
import 'models/bubble_settings.dart';
import 'dart:math';

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
  static const _notesKey = 'orb_notes';
  static const _settingsKey = 'orb_bubble_settings';
  static const _pinHashKey = 'orb_pin_hash';
  static const _pinEnabledKey = 'orb_pin_enabled';
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

  List<NoteItem> getNotes() {
    final json = _prefs.getString(_notesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => NoteItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addNote(String text) async {
    final notes = getNotes();
    notes.insert(0, NoteItem(
      id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(9999).toString(),
      text: text,
      timestamp: DateTime.now(),
    ));
    await _prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  Future<void> updateNote(String id, String text) async {
    final notes = getNotes();
    final index = notes.indexWhere((n) => n.id == id);
    if (index == -1) return;
    notes[index] = notes[index].copyWith(text: text, timestamp: DateTime.now());
    await _prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  Future<void> deleteNote(String id) async {
    final notes = getNotes();
    notes.removeWhere((n) => n.id == id);
    await _prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  BubbleSettings getSettings() {
    final json = _prefs.getString(_settingsKey);
    if (json == null) return const BubbleSettings();
    return BubbleSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveSettings(BubbleSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  String? getPinHash() => _prefs.getString(_pinHashKey);

  bool get isPinEnabled => _prefs.getBool(_pinEnabledKey) ?? false;

  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _prefs.setString(_pinHashKey, hash);
    await _prefs.setBool(_pinEnabledKey, true);
  }

  Future<void> removePin() async {
    await _prefs.remove(_pinHashKey);
    await _prefs.setBool(_pinEnabledKey, false);
  }

  bool verifyPin(String pin) {
    final hash = getPinHash();
    if (hash == null) return true;
    return _hashPin(pin) == hash;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
