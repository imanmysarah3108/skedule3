// --- Whole Week Schedule Page ---
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skedule3/main.dart';

class WeekSchedulePage extends StatefulWidget {
  const WeekSchedulePage({super.key});

  @override
  State<WeekSchedulePage> createState() => _WeekSchedulePageState();
}

class _WeekSchedulePageState extends State<WeekSchedulePage> {
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  String _selectedDay = DateFormat('EEEE').format(DateTime.now());
  late Future<List<Class>> _classesForSelectedDayFuture;

  @override
  void initState() {
    super.initState();
    _fetchClassesForDay(_selectedDay);
  }

  Future<void> _fetchClassesForDay(String day) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _classesForSelectedDayFuture = supabase
          .from('class')
          .select()
          .eq('day', day)
          .eq('id', userId) // Assuming user_id column
          .order('start_time', ascending: true)
          .then((data) => data.map((json) => Class.fromJson(json)).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Select Day',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: _daysOfWeek.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDay = newValue;
                  });
                  _fetchClassesForDay(newValue);
                }
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Class>>(
              future: _classesForSelectedDayFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No classes scheduled for $_selectedDay.'));
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final cls = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(cls.colorHex.replaceAll('#', '0xFF'))),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cls.subjectId,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '${cls.classType} - ${cls.lecturer}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '${cls.startTime.format(context)} - ${cls.endTime.format(context)} at ${cls.room}, ${cls.building}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}