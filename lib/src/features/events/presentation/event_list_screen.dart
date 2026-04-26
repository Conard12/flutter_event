import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('event_date');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements en Temps Réel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigation vers création
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final events = snapshot.data!;
          if (events.isEmpty) return const Center(child: Text('Aucun événement.'));

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event['title']),
                subtitle: Text(event['description'] ?? 'Pas de description'),
                trailing: Text(event['event_date'].toString().split('T')[0]),
              );
            },
          );
        },
      ),
    );
  }
}
