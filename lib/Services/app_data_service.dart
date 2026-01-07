import 'package:flutter/foundation.dart';

// === MODELS ===

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

  // Getters
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Habit> get habits => List.unmodifiable(_habits);
  List<Task> get tasks => List.unmodifiable(_tasks);

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
}