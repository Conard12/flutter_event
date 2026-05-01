import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'add_event_page.dart';
import '../domain/event.dart';

// ✅ IMPORTS DU DESIGN SYSTEM
import '../../../../core/widgets/event_card.dart';
import '../../../../core/theme/app_theme.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final Color primaryColor = const Color(0xFF6366F1);

    final Stream<List<Map<String, dynamic>>> eventsStream = supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('event_date', ascending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "Découvrir",
                style: TextStyle(
                  color: Color(0xFF1E1B4B),
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async => await supabase.auth.signOut(),
                ),
              ),
            ],
          ),

          // LISTE DES ÉVÉNEMENTS
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: eventsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text("Erreur : ${snapshot.error}")),
                );
              }

              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ),
                );
              }

              final events =
                  snapshot.data!.map((json) => Event.fromJson(json)).toList();

              if (events.isEmpty) {
                return SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Aucun événement prévu",
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final event = events[index];
                  return _buildPremiumEventCard(context, event);
                }, childCount: events.length),
              );
            },
          ),
        ],
      ),

      // BOUTON CRÉER PREMIUM
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "ORGANISER",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEventPage()),
            ),
      ),
    );
  }

  Widget _buildPremiumEventCard(BuildContext context, Event event) {
    final supabase = Supabase.instance.client;

    return FutureBuilder<int>(
      future: supabase
          .from('participants')
          .count()
          .eq('event_id', event.id)
          .then((response) => response),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return EventCard(
          title: event.title,
          date: "${event.date.day}/${event.date.month}",
          participantsCount: count,
          onTap: () => context.push('/event/${Uri.encodeComponent(event.id)}'),
        );
      },
    );
  }
}
