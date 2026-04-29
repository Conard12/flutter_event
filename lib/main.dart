import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'src/constants.dart';
import 'src/features/events/presentation/event_details_page.dart';
import 'src/features/events/presentation/event_list_screen.dart';
import 'src/features/auth/presentation/auth_screen.dart';

// ✅ IMPORTER TON THÈME
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

// Écoute les changements de session
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Configuration des routes
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = authState.value?.session;
      final isLoggingIn = state.matchedLocation == '/auth';

      if (session == null && !isLoggingIn) return '/auth';
      if (session != null && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/', builder: (context, state) => const EventListScreen()),
      GoRoute(
        path: '/event/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return EventDetailsPage(eventId: eventId);
        },
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Event Sync App',
      debugShowCheckedModeBanner: false,
      // ✅ APPLIQUER TON THÈME ICI
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}