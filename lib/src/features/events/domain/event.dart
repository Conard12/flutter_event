class Event {
  final String id;
  final String title;
  final DateTime date;
  final String creatorId;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.creatorId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['event_date']),
      creatorId: json['creator_id'],
    );
  }
}
