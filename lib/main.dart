import 'package:flutter/material.dart';
import 'app.dart';
import 'core/network/supabase_service.dart';

/// Entry point of the CodeGuard Exam application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const CodeGuardApp());
}
