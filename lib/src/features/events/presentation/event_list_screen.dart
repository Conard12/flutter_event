// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class EventListScreen extends StatelessWidget {
//   const EventListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final stream = Supabase.instance.client
//         .from('events')
//         .stream(primaryKey: ['id'])
//         .order('event_date');

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Événements en Temps Réel'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () => Supabase.instance.client.auth.signOut(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () {
//               // TODO: Navigation vers création
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: stream,
//         builder: (context, snapshot) {
//           if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
//           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

//           final events = snapshot.data!;
//           if (events.isEmpty) return const Center(child: Text('Aucun événement.'));

//           return ListView.builder(
//             itemCount: events.length,
//             itemBuilder: (context, index) {
//               final event = events[index];
//               return ListTile(
//                 title: Text(event['title']),
//                 subtitle: Text(event['description'] ?? 'Pas de description'),
//                 trailing: Text(event['event_date'].toString().split('T')[0]),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }







import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Stream pour récupérer les événements en temps réel (Point clé du projet)
    final stream = Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('event_date');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: [
          // BOUTON DECONNEXION FONCTIONNEL
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Déconnexion',
            onPressed: () async {
              // On appelle Supabase pour détruire la session
              await Supabase.instance.client.auth.signOut();
              // Pas besoin de context.go('/auth'), 
              // le Gatekeeper dans main.dart s'en occupe !
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigation vers création (Mission Personne 3)
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
          if (events.isEmpty) {
            return const Center(child: Text('Aucun événement pour le moment.'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.indigo),
                  title: Text(event['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(event['description'] ?? 'Pas de description'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}