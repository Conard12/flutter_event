class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime date; // Contient date + heure
  final String? creatorId;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.creatorId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.parse(json['event_date']),
      creatorId: json['creator_id'] ?? '',
    );
  }
}
