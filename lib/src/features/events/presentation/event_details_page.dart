import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/event.dart';
import '../../participants/domain/participant.dart';

// ✅ IMPORTS DU DESIGN SYSTEM
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final supabase = Supabase.instance.client;
  bool _isLoadingAction = false;

  // Flux temps réel pour les détails de l'événement
  Stream<List<Map<String, dynamic>>> get _eventStream => supabase
      .from('events')
      .stream(primaryKey: ['id'])
      .eq('id', widget.eventId);

  // Flux temps réel pour les participants de cet événement
  Stream<List<Map<String, dynamic>>> get _participantsStream => supabase
      .from('participants')
      .stream(primaryKey: ['event_id', 'profile_id'])
      .eq('event_id', widget.eventId)
      .order('joined_at');

  Future<void> _toggleParticipation(bool isJoined) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar('Veuillez vous connecter.', isError: true);
      return;
    }

    setState(() => _isLoadingAction = true);

    try {
      if (isJoined) {
        // Tentative de suppression avec vérification (select)
        final response = await supabase
            .from('participants')
            .delete()
            .eq('event_id', widget.eventId)
            .eq('profile_id', user.id)
            .select();

        if (response.isEmpty) {
          _showSnackBar('Impossible de quitter : permission refusée ou déjà retiré.', isError: true);
        } else {
          _showSnackBar('Vous avez quitté l’événement.');
        }
      } else {
        // Ajout
        await supabase.from('participants').insert({
          'event_id': widget.eventId,
          'profile_id': user.id,
          'joined_at': DateTime.now().toIso8601String(),
        });
        _showSnackBar('Participation confirmée !');
      }
    } on PostgrestException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Erreur de connexion.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Détails de l’événement'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _eventStream,
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasError) return Center(child: Text('Erreur : ${eventSnapshot.error}'));
          if (!eventSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final eventRows = eventSnapshot.data!;
          if (eventRows.isEmpty) return const Center(child: Text('Événement introuvable.'));
          final event = Event.fromJson(eventRows.first);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventInfoCard(event),
                const SizedBox(height: 24),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _participantsStream,
                  builder: (context, participantSnapshot) {
                    if (participantSnapshot.hasError) return Text('Erreur : ${participantSnapshot.error}');
                    
                    final participants = (participantSnapshot.data ?? [])
                        .map((json) => Participant.fromJson(json))
                        .toList();
                    
                    final isJoined = userId != null && participants.any((p) => p.profileId == userId);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomButton(
                          label: isJoined ? 'Quitter l’événement' : 'Rejoindre l’événement',
                          onPressed: () => _toggleParticipation(isJoined),
                          isLoading: _isLoadingAction,
                          icon: isJoined ? Icons.exit_to_app : Icons.person_add_alt_1,
                        ),
                        const SizedBox(height: 24),
                        _buildParticipantsList(participants, userId),
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

  Widget _buildEventInfoCard(Event event) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '${event.date.day}/${event.date.month}/${event.date.year}',
                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.access_time_filled, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '${event.date.hour}h${event.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              event.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantsList(List<Participant> participants, String? userId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Participants',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                '${participants.length}',
                style: const TextStyle(fontSize: 16, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (participants.isEmpty)
            const Text('Aucun participant pour le moment.', style: TextStyle(color: Color(0xFF6B7280)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final p = participants[index];
                final isMe = p.profileId == userId;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMe ? 'Vous' : (p.profileId.length > 8 ? '${p.profileId.substring(0, 8)}...' : p.profileId),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Moi',
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
