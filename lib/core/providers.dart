import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return Database.getInstance();
});
