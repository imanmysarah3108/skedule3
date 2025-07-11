import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skedule3/SubFabButton.dart';
import 'package:skedule3/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late Future<List<Class>> _todayClassesFuture;
  late Future<List<Assignment>> _upcomingTasksFuture;

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFabExpansion() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _fetchData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final today = DateFormat('EEEE').format(DateTime.now());
    _todayClassesFuture = supabase
        .from('class')
        .select()
        .eq('day', today)
        .eq('id', userId)
        .order('start_time', ascending: true)
        .then((data) => data.map((json) => Class.fromJson(json)).toList());

    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    _upcomingTasksFuture = supabase
        .from('assignment')
        .select('*, subject_id')
        .eq('id', userId)
        .eq('is_completed', false)
        .gte('due_date', DateFormat('yyyy-MM-dd').format(now))
        .lte('due_date', DateFormat('yyyy-MM-dd').format(sevenDaysLater.add(const Duration(days: 23))))
        .order('due_date', ascending: true)
        .then((data) => data.map((json) => Assignment.fromJson(json)).toList());

    setState(() {});
  }

  Future<void> _toggleTaskCompletion(Assignment assignment) async {
    try {
      await supabase
          .from('assignment')
          .update({'is_completed': !assignment.isCompleted})
          .eq('assignment_id', assignment.assignmentId);
      if (mounted) {
        showSnackBar(context, 'Task status updated!');
        _fetchData();
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
        title: const Text('Skedule  🗓️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodayClasses(context),
              const SizedBox(height: 32),
              _buildUpcomingTasks(context),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: _isFabExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_isFabExpanded,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SubFabButton(
                    icon: Icons.library_books_outlined,
                    label: 'Add Subject',
                    onTap: () {
                      _toggleFabExpansion();
                      Navigator.of(context).pushNamed('/add_subject');
                    },
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  SubFabButton(
                    icon: Icons.class_outlined,
                    label: 'Add Class',
                    onTap: () {
                      _toggleFabExpansion();
                      Navigator.of(context).pushNamed('/add_edit_class');
                    },
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  SubFabButton(
                    icon: Icons.assignment_add,
                    label: 'Add Task',
                    onTap: () {
                      _toggleFabExpansion();
                      Navigator.of(context).pushNamed('/add_task');
                    },
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: _toggleFabExpansion,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _animationController.value * 0.75 * 3.1416,
                  child: child,
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
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
            leading: const Icon(Icons.library_books_outlined),
            title: const Text('Add/ Edit Subject'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/add_subject');
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
    );
  }

  Widget _buildTodayClasses(BuildContext context) {
    return Column(
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
                                  cls.subjectId,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text('${cls.classType} - ${cls.lecturer}'),
                                Text('${cls.startTime.format(context)} - ${cls.endTime.format(context)} at ${cls.room}, ${cls.building}'),
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
      ],
    );
  }

  Widget _buildUpcomingTasks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        onChanged: (val) => _toggleTaskCompletion(task),
                        activeColor: Colors.green,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.subjectId.isNotEmpty)
                            Text(
                              task.subjectId,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color.fromARGB(255, 255, 236, 189),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                            ),
                          Text(
                            task.assignmentTitle,
                            style: TextStyle(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }
}
