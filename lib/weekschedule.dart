import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skedule3/main.dart'; // Assuming this imports `supabase` and `Class` model
import 'package:skedule3/edit_class.dart'; // Import your AddEditClassPage
import 'dart:developer';

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

  Future<Map<String, List<Class>>>? _allClassesGroupedByDayFuture;

  @override
  void initState() {
    super.initState();
    log('WeekSchedulePage: initState called. Fetching initial classes.');
    _allClassesGroupedByDayFuture = _fetchClassesInternal();
  }

  Future<Map<String, List<Class>>> _fetchClassesInternal() async {
    log('WeekSchedulePage: _fetchClassesInternal called.');
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      log('WeekSchedulePage: No user ID found, returning empty map.');
      return {};
    }

    try {
      final data = await supabase
          .from('class')
          .select()
          // Ensure 'class_id' is selected if it's the primary key for deletion
          .order('start_time', ascending: true);

      log('WeekSchedulePage: Fetched ${data.length} classes from Supabase.');

      final List<Class> allClasses = data.map((json) => Class.fromJson(json)).toList();
      final Map<String, List<Class>> groupedClasses = {};
      for (var day in _daysOfWeek) {
        groupedClasses[day] = [];
      }
      for (var cls in allClasses) {
        if (groupedClasses.containsKey(cls.day)) {
          groupedClasses[cls.day]!.add(cls);
        }
      }
      log('WeekSchedulePage: Grouped classes: ${groupedClasses.keys.map((k) => '$k: ${groupedClasses[k]!.length} classes').join(', ')}');
      return groupedClasses;
    } catch (e) {
      log('WeekSchedulePage: Error fetching classes: $e', error: e);
      rethrow; // Re-throw to be caught by FutureBuilder
    }
  }

  void _reloadClasses() {
    log('WeekSchedulePage: _reloadClasses called. Setting new future.');
    setState(() {
      _allClassesGroupedByDayFuture = _fetchClassesInternal(); // Assign a brand new future
    });
  }

  // Helper for showing SnackBars
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // New method to handle class deletion
  Future<void> _deleteClass(Class classToDelete) async {
    log('WeekSchedulePage: Attempting to delete class: ${classToDelete.subjectId} (class_id: ${classToDelete.classId})');

    // Show confirmation dialog
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${classToDelete.subjectId}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('Cancel'),
            ),
            FilledButton( // Use FilledButton for a more prominent action
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      log('WeekSchedulePage: Deletion confirmed for class_id: ${classToDelete.classId}');
      try {
        await supabase
            .from('class')
            .delete()
            .eq('class_id', classToDelete.classId); // Crucial: Delete by the unique class_id

        showSnackBar('Class "${classToDelete.subjectId}" deleted successfully!');
        log('WeekSchedulePage: Class successfully deleted from Supabase.');
        _reloadClasses(); // Refresh the list after deletion
      } catch (e) {
        showSnackBar('Failed to delete class: $e', isError: true);
        log('WeekSchedulePage: Error deleting class: $e', error: e);
      }
    } else {
      log('WeekSchedulePage: Deletion cancelled.');
    }
  }


  @override
  Widget build(BuildContext context) {
    log('WeekSchedulePage: build called.');
    final String currentDayName = DateFormat('EEEE').format(DateTime.now());
    final int initialTabIndex = _daysOfWeek.indexOf(currentDayName);

    return DefaultTabController(
      length: _daysOfWeek.length,
      initialIndex: initialTabIndex.clamp(0, _daysOfWeek.length - 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Weekly Schedule'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _daysOfWeek.map((day) => Tab(text: day)).toList(),
              ),
            ),
          ),
        ),
        body: FutureBuilder<Map<String, List<Class>>>(
          future: _allClassesGroupedByDayFuture,
          builder: (context, snapshot) {
            log('WeekSchedulePage: FutureBuilder builder called. Connection state: ${snapshot.connectionState}');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No classes scheduled for the week.'));
            } else {
              final Map<String, List<Class>> groupedClasses = snapshot.data!;
              return TabBarView(
                children: _daysOfWeek.map((day) {
                  final List<Class> classesForDay = groupedClasses[day] ?? [];

                  if (classesForDay.isEmpty) {
                    return Center(child: Text('No classes scheduled for $day.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: classesForDay.length,
                    itemBuilder: (context, index) {
                      final cls = classesForDay[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          // The main tap action for editing
                          onTap: () async {
                            log('WeekSchedulePage: Tapped on class for EDIT: ${cls.subjectId}');
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditClassPage(classToEdit: cls),
                              ),
                            );
                            log('WeekSchedulePage: Navigated back from edit. Result: $result');
                            if (result == true) {
                              log('WeekSchedulePage: Edit successful. Calling _reloadClasses().');
                              _reloadClasses();
                            } else {
                              log('WeekSchedulePage: Edit cancelled or failed, not reloading.');
                            }
                          },
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
                                // New: PopupMenuButton for actions (Delete, etc.)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _deleteClass(cls); // Call delete method
                                    }
                                    // Add other actions like 'edit' if you want a separate menu item
                                    // else if (value == 'edit') {
                                    //   // If you want edit to be also an option here, duplicate the onTap logic
                                    //   Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditClassPage(classToEdit: cls)));
                                    // }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                    // You can add more options here, e.g., view details
                                  ],
                                  icon: const Icon(Icons.more_vert), // Three dots icon
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }
}