import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/note_item.dart';
import '../../../core/providers.dart';

final notesProvider = FutureProvider<List<NoteItem>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.getNotes();
});
