import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class Task {
  final int id;
  final String title;
  final String description;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.completed = false,
  });

  // Convert Task to a Map for saving in shared preferences
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
    };
  }

  // Factory constructor to create a Task from a map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      completed: map['completed'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merli Todo App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Task> tasks = [];
  Task? currentTask;
  SharedPreferences? prefs;

  late TextEditingController taskNameController = TextEditingController();
  late TextEditingController taskDescriptionController =
      TextEditingController();
  bool showInputFields = false; // Flag to control input field visibility

  @override
  void initState() {
    super.initState();
    loadTasksFromSharedPreferences(); // Load tasks when the app starts
  }

  void loadTasksFromSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs!.getStringList('tasks');

    if (savedTasks != null) {
      setState(() {
        tasks = savedTasks
            .map((taskJson) => Task.fromMap(jsonDecode(taskJson)))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 224, 239),
      appBar: AppBar(
        title: Text('SomeTask 🌺'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: currentTask == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('🦝', style: TextStyle(fontSize: 60)))
                      ])
                : Column(
                    children: [
                      Text(
                        'Task: ${currentTask!.title}',
                        style: TextStyle(fontSize: 24),
                      ),
                      Text(
                        'Description: ${currentTask!.description}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (tasks.isNotEmpty) {
                final random = Random();
                final randomIndex = random.nextInt(tasks.length);
                setState(() {
                  currentTask = tasks[randomIndex];
                });
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('No Tasks saved'),
                      content: Text('Please add some tasks.'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Text('I want to do something!'),
          ),
          if (currentTask != null)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tasks.removeWhere((task) => task.id == currentTask!.id);
                  currentTask = null;
                  saveTasksToSharedPreferences();
                });
                // Display the image here
                // Check if the task was completed before showing the image

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Task Completed'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Yippie!! Wowsies, well done maus!'),
                          Image.asset(
                            'assets/happykitty.jpg', // Replace with the actual image path
                            width: 300,
                            height: 200,
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Task Done :3'),
            ),
          SizedBox(height: 20),
          Visibility(
            visible: showInputFields,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Task:',
                    style: TextStyle(fontSize: 20),
                  ),
                  TextFormField(
                    controller: taskNameController,
                    decoration: InputDecoration(labelText: 'Task Name'),
                  ),
                  TextFormField(
                    controller: taskDescriptionController,
                    decoration: InputDecoration(labelText: 'Task Description'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _addTask();
                    },
                    child: Text('Add Task'),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 181, 0, 45),
            ),
            onPressed: () {
              setState(() {
                showInputFields = !showInputFields; // Toggle visibility
              });
            },
            child: Text(showInputFields ? 'Cancel' : 'Add Task'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 181, 0, 45),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskListScreen(tasks: tasks),
                ),
              );
            },
            child: Text('View available Tasks'),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    final newTask = Task(
      id: tasks.length,
      title: taskNameController.text,
      description: taskDescriptionController.text,
    );
    setState(() {
      tasks.add(newTask);
      taskNameController.clear();
      taskDescriptionController.clear();
      showInputFields = false; // Hide input fields after adding a task
      saveTasksToSharedPreferences(); // Save tasks when a new one is added
    });
  }

  void saveTasksToSharedPreferences() async {
    final openTasks = tasks.where((task) => !task.completed).toList();
    final taskList = openTasks.map((task) => task.toMap()).toList();
    await prefs!.setStringList(
        'tasks', taskList.map((task) => jsonEncode(task)).toList());
  }
}

class TaskListScreen extends StatelessWidget {
  final List<Task> tasks;

  TaskListScreen({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Tasks'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Container(
            margin: EdgeInsets.all(
                8), // Add some margin to create a gap between tasks
            padding: EdgeInsets.all(12), // Add padding for spacing
            decoration: BoxDecoration(
              border: Border.all(color: Colors.pink, width: 2), // Border style
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            child: ListTile(
              title: Text(task.title, style: TextStyle(fontSize: 22)),
              subtitle: Text(task.description, style: TextStyle(fontSize: 18)),
            ),
          );
        },
      ),
    );
  }
}
