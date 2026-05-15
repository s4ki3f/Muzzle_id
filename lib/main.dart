import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/enrollment/screens/screen_1_registration.dart';
import 'features/sync/models/upload_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error (ignore if no options provided yet): $e');
  }

  // Initialize Hive for offline queue
  await Hive.initFlutter();
  Hive.registerAdapter(MuzzleUploadTaskAdapter());
  Hive.registerAdapter(AppModeAdapter());
  await Hive.openBox<MuzzleUploadTask>('uploadQueue');

  runApp(const ProviderScope(child: MuzzleIdApp()));
}

class MuzzleIdApp extends StatelessWidget {
  const MuzzleIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuzzleID',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RegistrationScreen(),
    );
  }
}
