// --- Home Page ---
import 'package:flutter/material.dart';
import 'package:skedule3/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Class>> _todayClassesFuture;
  late Future<List<Assignment>> _upcomingTasksFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      // Handle case where user is not logged in, perhaps navigate to login
      return;
    }

    // Fetch today's classes
    final today = DateFormat('EEEE').format(DateTime.now()); // Get full day name e.g., "Friday"
    _todayClassesFuture = supabase
        .from('class')
        .select()
        .eq('day', today)
        .eq('user_id', userId) // Assuming a user_id column in 'class' table
        .order('start_time', ascending: true)
        .then((data) => data.map((json) => Class.fromJson(json)).toList());

    // Fetch upcoming tasks (e.g., tasks due in the next 7 days and not completed)
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    _upcomingTasksFuture = supabase
        .from('assignment')
        .select()
        .eq('id', userId) // 'id' in assignment table refers to user_id
        .eq('is_completed', false)
        .gte('due_date', DateFormat('yyyy-MM-dd').format(now))
        .lte('due_date', DateFormat('yyyy-MM-dd').format(sevenDaysLater))
        .order('due_date', ascending: true)
        .then((data) => data.map((json) => Assignment.fromJson(json)).toList());

    setState(() {}); // Trigger rebuild to show loading indicators
  }

  Future<void> _toggleTaskCompletion(Assignment assignment) async {
    try {
      await supabase
          .from('assignment')
          .update({'is_completed': !assignment.isCompleted})
          .eq('assignment_id', assignment.assignmentId);
      if (mounted) {
        showSnackBar(context, 'Task status updated!');
        _fetchData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to update task: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skedule - Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skedule',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your daily schedule companion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Whole Week Schedule'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/week_schedule');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Add/Edit Class'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/add_edit_class');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Add Task'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/add_task');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/profile');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Schedule',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Class>>(
                future: _todayClassesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No classes scheduled for today.'));
                  } else {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                                        cls.subjectId, // Assuming subjectId is the subject code
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
              const SizedBox(height: 32),
              Text(
                'Upcoming Tasks',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Assignment>>(
                future: _upcomingTasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No upcoming tasks.'));
                  } else {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final task = snapshot.data![index];
                        Color priorityColor;
                        switch (task.priority.toLowerCase()) {
                          case 'high':
                            priorityColor = Colors.red;
                            break;
                          case 'medium':
                            priorityColor = Colors.orange;
                            break;
                          case 'low':
                            priorityColor = Colors.green;
                            break;
                          default:
                            priorityColor = Colors.grey;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (bool? newValue) {
                                _toggleTaskCompletion(task);
                              },
                              activeColor: Colors.green,
                            ),
                            title: Text(
                              task.assignmentTitle,
                              style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.desc,
                                  style: TextStyle(
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                Text(
                                  'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.priority.toUpperCase(),
                                style: TextStyle(
                                  color: priorityColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            onTap: () {
                              // Optional: Navigate to edit task page
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addClass',
            onPressed: () {
              Navigator.of(context).pushNamed('/add_edit_class');
            },
            child: const Icon(Icons.class_outlined),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'addTask',
            onPressed: () {
              Navigator.of(context).pushNamed('/add_task');
            },
            child: const Icon(Icons.assignment_add),
          ),
        ],
      ),
    );
  }
}