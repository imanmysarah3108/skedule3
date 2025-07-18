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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌞';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, currentRoute),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 4), 
              Text(
                'Have a great day!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 24), 
              _buildDateAndTimeZoneSection(context),
              const SizedBox(height: 24), 
              _buildTodayClasses(context),
              const SizedBox(height: 16),
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _animationController.value * 0.75 * 3.1416,
                  child: child,
                );
              },
              child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String? currentRoute) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skedule',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your daily schedule companion',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home_outlined),
            title: Text('Home'),
            selected: currentRoute == '/home', 
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), 
            selectedColor: Theme.of(context).colorScheme.primary, 
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/home') { 
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today_outlined),
            title: Text('Whole Week Schedule'),
            selected: currentRoute == '/week_schedule',
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            selectedColor: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/week_schedule') {
                Navigator.of(context).pushNamed('/week_schedule');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.library_books_outlined),
            title: Text('Add/Edit Subject'),
            selected: currentRoute == '/add_subject',
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            selectedColor: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/add_subject') {
                Navigator.of(context).pushNamed('/add_subject');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.add_box_outlined),
            title: Text('Add/Edit Class'),
            selected: currentRoute == '/add_edit_class',
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            selectedColor: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/add_edit_class') {
                Navigator.of(context).pushNamed('/add_edit_class');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment_outlined),
            title: Text('Add Task'),
            selected: currentRoute == '/add_task',
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            selectedColor: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/add_task') {
                Navigator.of(context).pushNamed('/add_task');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            selected: currentRoute == '/profile',
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            selectedColor: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/profile') {
                Navigator.of(context).pushNamed('/profile');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayClasses(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sectionColor = isDarkMode
        ? const Color(0xFFB8A9FF) 
        : const Color(0xFF7B61FF); 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sectionColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Today\'s Schedule',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
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
                return Center(
                  child: Text(
                    'No classes scheduled for today.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                );
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final cls = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
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
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cls.classType} - ${cls.lecturer}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cls.startTime.format(context)} - ${cls.endTime.format(context)} at ${cls.room}, ${cls.building}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
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
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sectionColor = isDarkMode
        ? const Color(0xFFB8A9FF) 
        : const Color(0xFF7B61FF); 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sectionColor.withOpacity(0.3), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 20,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Upcoming Tasks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
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
                return Center(
                  child: Text(
                    'No upcoming tasks.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                );
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
                        priorityColor = Colors.red.shade400;
                        break;
                      case 'medium':
                        priorityColor = Colors.orange.shade400;
                        break;
                      case 'low':
                        priorityColor = Colors.green.shade400;
                        break;
                      default:
                        priorityColor = Colors.grey.shade400;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (val) => _toggleTaskCompletion(task),
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.subjectId.isNotEmpty)
                              Text(
                                task.subjectId,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              task.assignmentTitle,
                              style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              task.desc,
                              style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: priorityColor.withOpacity(0.3),
                              width: 1,
                            ),
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
      ),
    );
  }

  Widget _buildDateAndTimeZoneSection(BuildContext context) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now); 
    final currentDate = DateFormat('dd').format(now); 
    final currentMonth = DateFormat('MMMM yyyy').format(now); 
    final currentTime = DateFormat('HH:mm:ss').format(now); 
    final timeZoneName = now.timeZoneName; 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1), 
            blurRadius: 10, 
            offset: const Offset(0, 6), 
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentDay,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), 
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                currentDate,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface, 
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                currentMonth,
                style: Theme.of(context).textTheme.titleLarge?.copyWith( 
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9), 
                    ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentTime,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface, 
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                timeZoneName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
