import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas Minimalista',
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
      home: TodoList(),
    );
  }
}

class Todo {
  String title;
  int estimatedMinutes;
  bool isDone;
  int elapsedSeconds;
  bool isRunning;
  int alertMinutes;
  int lastAlertTime;  // Novo campo para rastrear o último alerta

  Todo({
    required this.title,
    required this.estimatedMinutes,
    this.isDone = false,
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.alertMinutes = 0,
    this.lastAlertTime = 0,  // Inicializa com 0
  });
}

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  List<Todo> _todos = [];
  TextEditingController _titleController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  TextEditingController _alertController = TextEditingController();
  late Timer _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioLoaded = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), _updateTimers);
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('alert.mp3'));
      setState(() {
        _isAudioLoaded = true;
      });
      print('Áudio carregado com sucesso');
    } catch (e) {
      print('Erro ao carregar áudio: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateTimers(Timer timer) {
    setState(() {
      for (var todo in _todos) {
        if (todo.isRunning) {
          todo.elapsedSeconds++;
          if (todo.alertMinutes > 0) {
            int timeSinceLastAlert = todo.elapsedSeconds - todo.lastAlertTime;
            if (timeSinceLastAlert >= todo.alertMinutes * 60) {
              _showAlert(todo.title);
              todo.lastAlertTime = todo.elapsedSeconds;  // Atualiza o tempo do último alerta
            }
          }
        }
      }
    });
  }

  void _showAlert(String title) {
    _playAlertSound();
    print('Alerta para a tarefa: $title');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tempo de alerta atingido para: $title'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _playAlertSound() async {
    if (!_isAudioLoaded) {
      print('Áudio não carregado. Tentando carregar novamente...');
      await _loadAudio();
    }
    try {
      await _audioPlayer.stop(); // Para garantir que o áudio comece do início
      await _audioPlayer.resume();
      print('Tentativa de tocar o áudio');
    } catch (e) {
      print('Erro ao tocar áudio: $e');
    }
  }

  void _addTodo() {
    if (_titleController.text.isNotEmpty && _timeController.text.isNotEmpty) {
      setState(() {
        _todos.add(Todo(
          title: _titleController.text,
          estimatedMinutes: int.parse(_timeController.text),
          alertMinutes: int.tryParse(_alertController.text) ?? 0,
        ));
        _titleController.clear();
        _timeController.clear();
        _alertController.clear();
      });
    }
  }

  void _toggleTodo(int index) {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  void _toggleTimer(int index) {
    setState(() {
      _todos[index].isRunning = !_todos[index].isRunning;
    });
  }

  void _resetTimer(int index) {
    setState(() {
      _todos[index].elapsedSeconds = 0;
      _todos[index].isRunning = false;
      _todos[index].lastAlertTime = 0;  // Reseta o tempo do último alerta
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _editTodo(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _editTitleController = TextEditingController(text: _todos[index].title);
        final TextEditingController _editTimeController = TextEditingController(text: _todos[index].estimatedMinutes.toString());
        final TextEditingController _editAlertController = TextEditingController(text: _todos[index].alertMinutes.toString());
        return AlertDialog(
          title: Text('Editar Tarefa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editTitleController,
                decoration: InputDecoration(hintText: "Título da tarefa"),
              ),
              TextField(
                controller: _editTimeController,
                decoration: InputDecoration(hintText: "Tempo estimado (minutos)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _editAlertController,
                decoration: InputDecoration(hintText: "Tempo de alerta (minutos)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Salvar'),
              onPressed: () {
                setState(() {
                  _todos[index].title = _editTitleController.text;
                  _todos[index].estimatedMinutes = int.parse(_editTimeController.text);
                  _todos[index].alertMinutes = int.tryParse(_editAlertController.text) ?? 0;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarefas'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _todos[index].title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  decoration: _todos[index].isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(_todos[index].isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                              onPressed: () => _toggleTodo(index),
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Estimado: ${_todos[index].estimatedMinutes} minutos',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Tempo gasto: ${_formatTime(_todos[index].elapsedSeconds)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Alerta: ${_todos[index].alertMinutes} minutos',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(_todos[index].isRunning ? Icons.pause : Icons.play_arrow),
                                  onPressed: () => _toggleTimer(index),
                                  color: Colors.black54,
                                ),
                                IconButton(
                                  icon: Icon(Icons.replay),
                                  onPressed: () => _resetTimer(index),
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editTodo(index),
                                  color: Colors.black54,
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteTodo(index),
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Título da tarefa',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    hintText: 'Tempo estimado (minutos)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _alertController,
                  decoration: InputDecoration(
                    hintText: 'Tempo de alerta (minutos)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: Text('Adicionar Tarefa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
