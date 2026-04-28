import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/event.dart';
import '../../participants/domain/participant.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final supabase = Supabase.instance.client;
  bool _isLoadingAction = false;
  late Future<List<Participant>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _fetchParticipants();
  }

  Stream<List<Map<String, dynamic>>> get _eventStream => supabase
      .from('events')
      .stream(primaryKey: ['id'])
      .eq('id', widget.eventId);

  Future<List<Participant>> _fetchParticipants() async {
    final rows =
        await supabase
                .from('participants')
                .select()
                .eq('event_id', widget.eventId)
                .order('joined_at', ascending: true)
            as List<dynamic>;

    final normalizedRows =
        rows
            .map(
              (row) => Map<String, dynamic>.from(row as Map<dynamic, dynamic>),
            )
            .toList();

    return normalizedRows.map((json) => Participant.fromJson(json)).toList();
  }

  Future<void> _toggleParticipation(bool isJoined) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar('Utilisateur introuvable.', isError: true);
      return;
    }

    setState(() => _isLoadingAction = true);

    try {
      if (isJoined) {
        await supabase.from('participants').delete().match({
          'event_id': widget.eventId,
          'profile_id': user.id,
        });
        _showSnackBar('Vous avez quitté l’événement.');
      } else {
        await supabase.from('participants').insert({
          'event_id': widget.eventId,
          'profile_id': user.id,
          'joined_at': DateTime.now().toIso8601String(),
        });
        _showSnackBar('Participation confirmée !');
      }

      if (mounted) {
        setState(() {
          _participantsFuture = _fetchParticipants();
        });
      }
    } on PostgrestException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      _showSnackBar('Une erreur est survenue, réessayez.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatJoinedAt(DateTime joinedAt) {
    return '${joinedAt.day.toString().padLeft(2, '0')}/${joinedAt.month.toString().padLeft(2, '0')} ${joinedAt.hour.toString().padLeft(2, '0')}h${joinedAt.minute.toString().padLeft(2, '0')}';
  }

  String _displayParticipantName(String profileId, String? userId) {
    if (profileId == userId) return 'Vous';
    return profileId.length > 8 ? '${profileId.substring(0, 8)}...' : profileId;
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Détails de l’événement'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1B4B),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _eventStream,
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasError) {
            return Center(child: Text('Erreur : ${eventSnapshot.error}'));
          }

          if (!eventSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            );
          }

          final eventRows = eventSnapshot.data!;
          if (eventRows.isEmpty) {
            return const Center(child: Text('Événement introuvable.'));
          }

          final event = Event.fromJson(eventRows.first);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5267),
                            ),
                          ),
                          const SizedBox(width: 18),
                          const Icon(
                            Icons.access_time_filled,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${event.date.hour.toString().padLeft(2, '0')}h${event.date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5267),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (event.description != null &&
                          event.description!.isNotEmpty)
                        Text(
                          event.description!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF4B5267),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<Participant>>(
                  future: _participantsFuture,
                  builder: (context, participantSnapshot) {
                    if (participantSnapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          'Erreur participants : ${participantSnapshot.error}',
                        ),
                      );
                    }

                    if (!participantSnapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      );
                    }

                    final participants = participantSnapshot.data!;
                    final isJoined =
                        userId != null &&
                        participants.any((p) => p.profileId == userId);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed:
                              _isLoadingAction
                                  ? null
                                  : () => _toggleParticipation(isJoined),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isJoined
                                    ? Colors.redAccent
                                    : const Color(0xFF1E1B4B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isLoadingAction
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    isJoined
                                        ? 'Quitter l’événement'
                                        : 'Rejoindre l’événement',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Participants',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  Text(
                                    '${participants.length}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (participants.isEmpty)
                                const Text(
                                  'Aucun participant pour le moment. Soyez le premier !',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: participants.length,
                                  separatorBuilder:
                                      (_, __) => const Divider(height: 16),
                                  itemBuilder: (context, index) {
                                    final participant = participants[index];
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _displayParticipantName(
                                                participant.profileId,
                                                userId,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E1B4B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatJoinedAt(
                                                participant.joinedAt,
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (participant.profileId == userId)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF6366F1,
                                              ).withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Vous',
                                              style: TextStyle(
                                                color: Color(0xFF6366F1),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
