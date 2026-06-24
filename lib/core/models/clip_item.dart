import 'package:equatable/equatable.dart';

class ClipItem extends Equatable {
  final String text;
  final DateTime timestamp;
  final bool isFavorite;

  const ClipItem({
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [text, timestamp, isFavorite];

  ClipItem copyWith({String? text, DateTime? timestamp, bool? isFavorite}) {
    return ClipItem(
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isFavorite': isFavorite,
  };

  factory ClipItem.fromJson(Map<String, dynamic> json) => ClipItem(
    text: json['text'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    isFavorite: json['isFavorite'] as bool? ?? false,
  );
}
