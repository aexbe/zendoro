// lib/pages/routine_planner_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../models/tasks_entry_data.dart';
import '../models/user_model.dart';

class RoutinePlannerWidget extends StatefulWidget {
  const RoutinePlannerWidget({super.key});

  @override
  State<RoutinePlannerWidget> createState() => _RoutinePlannerWidgetState();
}

class _RoutinePlannerWidgetState extends State<RoutinePlannerWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();

  UserModel? _currentUser;
  late Box<UserModel> _usersBox;
  late Box<UserModel> _userBox; // for 'currentUser'

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initBoxesAndLoadUser();
  }

  Future<void> _initBoxesAndLoadUser() async {
    try {
      _usersBox = Hive.box<UserModel>('usersBox');
      _userBox = Hive.box<UserModel>('userBox');

      // Load current user from userBox('currentUser') or fallback to first user in usersBox
      UserModel? user = _userBox.get('currentUser');
      if (user == null && _usersBox.isNotEmpty) {
        user = _usersBox.getAt(0);
      }

      if (user != null) {
        // Migrate if needed (old map-based tasks -> typed list)
        user = _migrateTasksIfNeeded(user);
        // Ensure boxes have the migrated copy as well
        await _saveUserToBoxes(user);
      }

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tasks: $e';
        _isLoading = false;
      });
    }
  }

  UserModel _migrateTasksIfNeeded(UserModel user) {
    if (user.tasks != null && user.tasks!.isNotEmpty) return user;

    // Detect if there's an old `tasks` stored as dynamic (map) - try to read raw box
    // NOTE: this is best-effort; adapt if your previous storage key/location differs.
    //final raw = user.tasks; // if null, nothing to migrate
    // If `raw` is null, nothing to migrate. If earlier you stored tasks somewhere else, handle that case.
    return user;
  }

  Future<void> _saveUserToBoxes(UserModel user) async {
    final emailKey = user.email.trim().toLowerCase();
    await _usersBox.put(emailKey, user);
    await _userBox.put('currentUser', user);
  }

  List<TasksEntryData> _getTasks() {
    return List<TasksEntryData>.from(_currentUser?.tasks ?? []);
  }

  Future<void> _addNewRoutine(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final duration = double.tryParse(_durationController.text.trim()) ?? 0.0;

      final newTask = TasksEntryData(task: title, completed: false, duration: duration);

      // Update in-memory
      _currentUser ??= UserModel(
        name: 'Guest',
        email: '',
        password: '',
        gender: '',
        age: 0,
        task: [],
      );
      _currentUser!.tasks ??= [];
      _currentUser!.tasks!.add(newTask);

      // Persist
      await _saveUserToBoxes(_currentUser!);

      // UI updates
      _titleController.clear();
      _durationController.clear();
      Navigator.pop(context);
      setState(() {});
    }
  }

  Future<void> _deleteRoutineAt(int index) async {
    if (_currentUser == null) return;
    if (_currentUser!.tasks == null || index < 0 || index >= _currentUser!.tasks!.length) return;

    _currentUser!.tasks!.removeAt(index);
    await _saveUserToBoxes(_currentUser!);
    setState(() {});
  }

  Future<void> _toggleRoutineAt(int index) async {
    if (_currentUser == null) return;
    final list = _currentUser!.tasks;
    if (list == null || index < 0 || index >= list.length) return;

    final old = list[index];
    final updated = TasksEntryData(
      task: old.task,
      completed: !old.completed,
      duration: old.duration,
    );

    list[index] = updated;
    await _saveUserToBoxes(_currentUser!);
    setState(() {});
  }

  void _showAddRoutineDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                    hintText: 'e.g. Evening Walk',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (mins)',
                    hintText: 'e.g. 30',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () { _titleController.clear(); _durationController.clear(); Navigator.pop(context); }, child: const Text('Cancel')),
            ElevatedButton(onPressed: () => _addNewRoutine(context), child: const Text('Save')),
          ],
        );
      },
    );
  }

  Widget _buildRoutineList() {
    final tasks = _getTasks();
    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks yet. Add one!"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = tasks[index];
        return Dismissible(
          key: ValueKey(index),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text('Delete this task?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ),
            );
          },
          onDismissed: (_) => _deleteRoutineAt(index),
          child: Container(
                  width: MediaQuery.of(context).size.width - 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black26,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),

            child: ListTile(
              leading: Checkbox(
                value: t.completed,
                onChanged: (_) => _toggleRoutineAt(index),
                activeColor: const Color(0xFF15161E),
                side: const BorderSide(width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              title: Text(t.task, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF15161E), fontSize: 18, fontWeight: FontWeight.w400, decoration: t.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,)),
              subtitle: t.duration > 0 ? Text("${t.duration} mins", style: GoogleFonts.plusJakartaSans(fontSize: 14)) : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Planner', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF15161E), fontSize: 22, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoutineDialog,
        icon: const Icon(Icons.add),
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('Add New Task', 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF15161E))
          ),
        ),
      ),
      body: _buildRoutineList(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
