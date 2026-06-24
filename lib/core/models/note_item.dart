class NoteItem {
  final String id;
  final String text;
  final DateTime timestamp;

  const NoteItem({
    required this.id,
    required this.text,
    required this.timestamp,
  });

  NoteItem copyWith({String? id, String? text, DateTime? timestamp}) {
    return NoteItem(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] as String,
    text: json['text'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
  );
}
