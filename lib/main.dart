import 'package:flutter/material.dart';
import 'package:skedule3/add_subject.dart';
import 'package:skedule3/add_task.dart';
import 'package:skedule3/edit_class.dart';
import 'package:skedule3/homepage.dart';
import 'package:skedule3/login.dart'; // Assuming you have this file
import 'package:skedule3/profile.dart';
import 'package:skedule3/signup.dart'; // Assuming you have this file
import 'package:skedule3/weekschedule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

const SUPABASE_URL = 'https://ivhpkpjdgirodyjvypwd.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml2aHBrcGpkZ2lyb2R5anZ5cHdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2NDU1NzMsImV4cCI6MjA2NjIyMTU3M30.Tev4ouZoxt8XpWsOn_PYDx0mtLLoJsfqPRgZoEDdVYY';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SkeduleApp(),
    ),
  );
}

class SkeduleApp extends StatefulWidget {
  const SkeduleApp({super.key});

  @override
  State<SkeduleApp> createState() => _SkeduleAppState();
}

class _SkeduleAppState extends State<SkeduleApp> {
  // REMOVED THE onAuthStateChange.listen FROM HERE
  // @override
  // void initState() {
  //   super.initState();
  //   Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  //     final event = data.event;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (event == AuthChangeEvent.signedIn) {
  //         Navigator.of(context).pushReplacementNamed('/home');
  //       } else if (event == AuthChangeEvent.signedOut) {
  //         Navigator.of(context).pushReplacementNamed('/login');
  //       }
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Skedule',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.grey[850],
        cardColor: Colors.grey[800],
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[700],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
          ),
        ),
      ),
      // This initialRoute logic is correct and handles the starting point
      initialRoute: Supabase.instance.client.auth.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/week_schedule': (context) => const WeekSchedulePage(),
        '/add_edit_class': (context) => const AddEditClassPage(),
        '/add_task': (context) => const AddTaskPage(),
        '/profile': (context) => const ProfilePage(),
        '/add_subject': (context) => const AddSubjectPage(),
        '/privacy-policy': (context) => const PrivacyPolicyPage(),
      },
    );
  }
}

final supabase = Supabase.instance.client;

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'This is the privacy policy and terms of use for the Skedule app.\n\n'
            '1. Your data is stored securely using Supabase.\n'
            '2. We don’t share your data with third parties.\n'
            '3. Use this app responsibly for academic scheduling purposes.\n'
            '4. By using Skedule, you agree to these terms.\n\n'
            'Please reach out to skedule@yahoo.com if you have any questions.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Subject {
  final String subjectId;
  final String subjectTitle;

  Subject({
    required this.subjectId,
    required this.subjectTitle,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      subjectTitle: json['subject_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'subject_title': subjectTitle,
    };
  }
}

class Class {
  final String classId;
  final String subjectId;
  final String classType;
  final String building;
  final String room;
  final String lecturer;
  final String day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String colorHex;
  final bool reminder;
  final String id; // Add this field to match Supabase 'id' column for userId

  Class({
    required this.classId,
    required this.subjectId,
    required this.classType,
    required this.building,
    required this.room,
    required this.lecturer,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.colorHex,
    required this.reminder,
    required this.id, // Make it required
  });

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      classId: json['class_id'],
      subjectId: json['subject_id'],
      classType: json['class_type'],
      building: json['building'],
      room: json['room'],
      lecturer: json['lecturer'],
      day: json['day'],
      startTime: TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 ${json['start_time']}')),
      endTime: TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 ${json['end_time']}')),
      colorHex: json['color_hex'],
      reminder: json['reminder'],
      id: json['id'], // Ensure 'id' is parsed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'subject_id': subjectId,
      'class_type': classType,
      'building': building,
      'room': room,
      'lecturer': lecturer,
      'day': day,
      'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      'color_hex': colorHex,
      'reminder': reminder,
      'id': id,
    };
  }
}

class Assignment {
  final String assignmentId;
  final String desc;
  final String subjectId;
  final DateTime dueDate;
  final String id;
  final String assignmentTitle;
  bool isCompleted;
  String priority;

  Assignment({
    required this.assignmentId,
    required this.desc,
    required this.subjectId,
    required this.dueDate,
    required this.id,
    required this.assignmentTitle,
    this.isCompleted = false,
    this.priority = 'medium',
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentId: json['assignment_id'],
      desc: json['desc'],
      subjectId: json['subject_id'],
      dueDate: DateTime.parse(json['due_date']),
      id: json['id'],
      assignmentTitle: json['assignment_title'],
      isCompleted: json['is_completed'] ?? false,
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'desc': desc,
      'subject_id': subjectId,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'id': id,
      'assignment_title': assignmentTitle,
      'is_completed': isCompleted,
      'priority': priority,
    };
  }
}

void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}
