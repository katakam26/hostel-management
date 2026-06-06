import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/role_router.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase not configured yet — show a friendly setup screen instead of
    // crashing, so the project is runnable before `flutterfire configure`.
    firebaseError = e;
  }

  runApp(HostelApp(firebaseError: firebaseError));
}

class HostelApp extends StatelessWidget {
  final Object? firebaseError;
  const HostelApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    if (firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _FirebaseSetupScreen(),
      );
    }

    final auth = AuthService()..bootstrap();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Hostel Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RoleRouter(),
      ),
    );
  }
}

/// Shown when Firebase hasn't been configured yet.
class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56),
                const SizedBox(height: 16),
                Text('Firebase not connected yet',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text(
                  'The app skeleton is ready. To enable login and data:\n\n'
                  '1. Create a Firebase project at console.firebase.google.com\n'
                  '2. Run:  dart pub global activate flutterfire_cli\n'
                  '3. Run:  flutterfire configure\n'
                  '4. Enable Authentication, Firestore, and Storage\n'
                  '5. Restart the app',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
