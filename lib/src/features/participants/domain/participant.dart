class Participant {
  final String eventId;
  final String profileId;
  final DateTime joinedAt;

  Participant({
    required this.eventId,
    required this.profileId,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      eventId: json['event_id'],
      profileId: json['profile_id'],
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }
}
