class Event {
  final String name;
  final String imageUrl;
  final int maxParticipants;
  final int currentParticipants;
  final DateTime dateTime;

  Event({
    required this.name,
    required this.imageUrl,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.dateTime,
  });

  int get slotsLeft =>
      (maxParticipants - currentParticipants).clamp(0, maxParticipants);

  bool get isFull => slotsLeft == 0;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      maxParticipants: json['maxParticipants'] as int,
      currentParticipants: json['currentParticipants'] as int,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  Event copyWith({
    String? name,
    String? imageUrl,
    int? maxParticipants,
    int? currentParticipants,
    DateTime? dateTime,
  }) {
    return Event(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}
