import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';// === MODELS ===

class Tag {
  final String id;
  String name;
  Color color;
  bool isArchived;

  Tag({
    required this.id,
    required this.name,
    required this.color,
    this.isArchived = false,
  });

  Tag copyWith({String? name, Color? color, bool? isArchived}) {
    return Tag(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'isArchived': isArchived,
    };
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}

class Pillar {
  final String id;
  String name;
  List<String> subPillars;

  Pillar({
    required this.id,
    required this.name,
    List<String>? subPillars,
  }) : subPillars = subPillars ?? [];

  Pillar copyWith({String? name, List<String>? subPillars}) {
    return Pillar(
      id: id,
      name: name ?? this.name,
      subPillars: subPillars ?? this.subPillars,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subPillars': subPillars,
    };
  }

  factory Pillar.fromJson(Map<String, dynamic> json) {
    return Pillar(
      id: json['id'] as String,
      name: json['name'] as String,
      subPillars: List<String>.from(json['subPillars'] ?? []),
    );
  }
}


class Goal {
  final String id;
  String title;
  String description;
  DateTime? deadline;
  bool isCompleted;
  List<String> linkedTaskIds;
  DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.deadline,
    this.isCompleted = false,
    this.linkedTaskIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Goal copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    List<String>? linkedTaskIds,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
      createdAt: createdAt,
    );
  }
}

class Habit {
  final String id;
  String title;
  String? description;
  List<DateTime> completedDates;
  int streakCount;
  DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    this.description,
    List<DateTime>? completedDates,
    this.streakCount = 0,
    DateTime? createdAt,
  }) : completedDates = completedDates ?? [],
       createdAt = createdAt ?? DateTime.now();

  bool isCompletedOnDate(DateTime date) {
    return completedDates.any((d) =>
      d.year == date.year && d.month == date.month && d.day == date.day
    );
  }

  Habit copyWith({
    String? title,
    String? description,
    List<DateTime>? completedDates,
    int? streakCount,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completedDates: completedDates ?? this.completedDates,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt,
    );
  }
}

class Task {
  final String id;
  String title;
  String? description;
  DateTime? dueDate;
  bool isCompleted;
  String? linkedGoalId;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.linkedGoalId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? linkedGoalId,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      createdAt: createdAt,
    );
  }
}

// === MAIN DATA SERVICE ===

class AppDataService extends ChangeNotifier {
  final List<Goal> _goals = [];
  final List<Habit> _habits = [];
  final List<Task> _tasks = [];
  
  final List<Tag> _tags = [
    Tag(id: 't1', name: 'High Priority', color: Colors.red),
    Tag(id: 't2', name: 'Deep Work', color: Colors.purple),
    Tag(id: 't3', name: 'Errand', color: Colors.blueGrey),
  ];
  
  final List<Pillar> _pillars = [
    Pillar(id: 'p1', name: 'Faith', subPillars: ['Prayer', 'Meditation']),
    Pillar(id: 'p2', name: 'Health', subPillars: ['Fitness', 'Diet']),
    Pillar(id: 'p3', name: 'Relationships', subPillars: ['Family', 'Friends']),
    Pillar(id: 'p4', name: 'Optimization', subPillars: ['Finance', 'Home']),
    Pillar(id: 'p5', name: 'Education', subPillars: ['Reading', 'Courses']),
    Pillar(id: 'p6', name: 'Work', subPillars: ['Career', 'Side Hustle']),
    Pillar(id: 'p7', name: 'Creativity', subPillars: ['Art', 'Music']),
  ];

  // Getters
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Habit> get habits => List.unmodifiable(_habits);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Tag> get tags => List.unmodifiable(_tags);
  List<Tag> get activeTags => _tags.where((t) => !t.isArchived).toList();
  List<Pillar> get pillars => List.unmodifiable(_pillars);

  // === TAG METHODS ===
  void addTag(Tag tag) {
    _tags.add(tag);
    notifyListeners();
    syncToFirebase();
  }

  void updateTag(Tag tag) {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
      notifyListeners();
      syncToFirebase();
    }
  }

  void deleteTag(String id) {
    _tags.removeWhere((t) => t.id == id);
    notifyListeners();
    syncToFirebase();
  }

  // === PILLAR METHODS ===
  void addPillar(Pillar pillar) {
    _pillars.add(pillar);
    notifyListeners();
    syncToFirebase();
  }

  void updatePillar(Pillar pillar) {
    final index = _pillars.indexWhere((p) => p.id == pillar.id);
    if (index != -1) {
      _pillars[index] = pillar;
      notifyListeners();
      syncToFirebase();
    }
  }

  void deletePillar(String id) {
    _pillars.removeWhere((p) => p.id == id);
    notifyListeners();
    syncToFirebase();
  }

  // === GOAL METHODS ===
  
  void addGoal(Goal goal) {
    _goals.add(goal);
    notifyListeners();
  }

  void updateGoal(Goal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      notifyListeners();
    }
  }

  void deleteGoal(String goalId) {
    _goals.removeWhere((g) => g.id == goalId);
    // Remove tasks linked to this goal
    _tasks.where((t) => t.linkedGoalId == goalId).forEach((t) {
      t.linkedGoalId = null;
    });
    notifyListeners();
  }

  void toggleGoalCompletion(String goalId) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      _goals[index].isCompleted = !_goals[index].isCompleted;
      notifyListeners();
    }
  }

  Goal? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((g) => g.id == goalId);
    } catch (e) {
      return null;
    }
  }

  // === HABIT METHODS ===

  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      notifyListeners();
    }
  }

  void deleteHabit(String habitId) {
    _habits.removeWhere((h) => h.id == habitId);
    notifyListeners();
  }

  void toggleHabitForDate(String habitId, DateTime date) {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = _habits[index];
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final existingIndex = habit.completedDates.indexWhere((d) =>
      d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day
    );

    if (existingIndex != -1) {
      habit.completedDates.removeAt(existingIndex);
      if (habit.streakCount > 0) habit.streakCount--;
    } else {
      habit.completedDates.add(dateOnly);
      habit.streakCount++;
    }
    
    notifyListeners();
  }

  List<Habit> getHabitsForDate(DateTime date) {
    return _habits.where((habit) => habit.isCompletedOnDate(date)).toList();
  }

  // === TASK METHODS ===

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
    }
  }

  List<Task> getTasksForGoal(String goalId) {
    return _tasks.where((t) => t.linkedGoalId == goalId).toList();
  }

  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == date.year &&
             task.dueDate!.month == date.month &&
             task.dueDate!.day == date.day;
    }).toList();
  }

  // === CALENDAR HELPER METHODS ===

  Map<DateTime, List<dynamic>> getEventsForMonth(DateTime month) {
    Map<DateTime, List<dynamic>> events = {};

    // Add tasks with due dates
    for (var task in _tasks) {
      if (task.dueDate != null && 
          task.dueDate!.year == month.year && 
          task.dueDate!.month == month.month) {
        final dateKey = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        events[dateKey] = [...(events[dateKey] ?? []), task];
      }
    }

    // Add completed habits
    for (var habit in _habits) {
      for (var completedDate in habit.completedDates) {
        if (completedDate.year == month.year && completedDate.month == month.month) {
          final dateKey = DateTime(completedDate.year, completedDate.month, completedDate.day);
          events[dateKey] = [...(events[dateKey] ?? []), habit];
        }
      }
    }

    return events;
  }

  // === FIREBASE SYNC ===
  Future<void> syncToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set({
        'tags': _tags.map((t) => t.toJson()).toList(),
        'pillars': _pillars.map((p) => p.toJson()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to sync app data: $e");
    }
  }

  Future<void> loadFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data.containsKey('tags')) {
          final tagsList = data['tags'] as List;
          _tags.clear();
          _tags.addAll(tagsList.map((t) => Tag.fromJson(Map<String, dynamic>.from(t))));
        }
        if (data.containsKey('pillars')) {
          final pillarsList = data['pillars'] as List;
          _pillars.clear();
          _pillars.addAll(pillarsList.map((p) => Pillar.fromJson(Map<String, dynamic>.from(p))));
        }
        notifyListeners();
      } else {
        // If no data exists, sync the defaults to Firebase
        await syncToFirebase();
      }
    } catch (e) {
      debugPrint("Failed to load app data: $e");
    }
  }
}