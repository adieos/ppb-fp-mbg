import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monitorbg/screens/kowner/kowner_shell.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'services/admin_firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiGizi MBG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF)),
      ),
      home: const AuthGate(),
    );
  }
}

/// Listens to Firebase auth state, then reads Firestore role,
/// and routes to the correct shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (!snapshot.hasData) return const LoginScreen();

        // User is signed in — resolve their role from Firestore
        return FutureBuilder<UserModel?>(
          future: AdminFirestoreService().getUser(snapshot.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            final user = userSnap.data;

            // Route based on role
            if (user?.isAdmin == true) {
              return const AdminShell();
            }

            // Kitchen owner shell — to be built by Dev 1
            // Placeholder until their screens are ready
            // return const _KitchenOwnerPlaceholder();
            return const KownerShell();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1117),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
    );
  }
}

/// Temporary placeholder — replace with KitchenOwnerShell once Dev 1 is done.
class _KitchenOwnerPlaceholder extends StatelessWidget {
  const _KitchenOwnerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, color: Color(0xFF6C63FF), size: 52),
            const SizedBox(height: 16),
            const Text(
              'Kitchen Owner screens',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coming soon (Dev 1)',
              style: TextStyle(color: Color(0xFF8A8FA8)),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
