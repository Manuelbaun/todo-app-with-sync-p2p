import 'dart:io';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

import 'sync/dao.dart';
import 'sync/index.dart';

int localNodeName;
void main(List<String> arguments) {
  localNodeName = faker.randomGenerator.integer(99999);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key) {
    syncWrapper = SyncWrapper.getInstance(localNodeName);
  }

  SyncWrapper syncWrapper;

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocket ws;
  bool connected = false;

  void connect() async {
    /// Setup connection
    try {
      ws = await WebSocket.connect('ws://localhost:8000');

      if (ws?.readyState == WebSocket.open) {
        // dirty hack to clear all connections
        SyncWrapper.instance.protocol.disconnectFromAll();
        SyncWrapper.instance.protocol.registerConnection(ws);
        setState(() => connected = true);
      } else {
        print('[!]Connection Denied');
        setState(() => connected = false);
      }
    } catch (e) {
      print(e);
    }
  }

  void disconnect() async {
    try {
      ws.close();
      setState(() => connected = false);
    } catch (e) {
      print(e);
    }
  }

  void _addTODO() {
    SyncWrapper.instance.syn.transaction(() {
      final t = SyncWrapper.instance.todos.create();
      final n = faker.job.title();
      t.title = n;
      t.status = false;
    });
  }

  void _addPEOPLE() {
    SyncWrapper.instance.syn.transaction(() {
      final t = SyncWrapper.instance.assignees.create();

      t.firstName = faker.person.firstName();
      t.lastName = faker.person.lastName();
      t.age = faker.randomGenerator.integer(80, min: 20);
    });
  }

  Map<String, TextEditingController> todoTitles = {};
  Map<String, TextEditingController> firstName = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
            ),
            VerticalDivider(),
            IconButton(
              icon: Icon(Icons.call),
              onPressed: connect,
              color: Colors.greenAccent,
            ),
            IconButton(
              icon: Icon(Icons.call_end),
              onPressed: disconnect,
              color: Colors.redAccent,
            ),
            IconButton(
              icon: Icon(connected ? Icons.wifi_tethering : Icons.network_wifi),
              onPressed: disconnect,
              color: connected ? Colors.green : Colors.grey,
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          constraints: BoxConstraints.expand(),
          child: Row(
            children: [
              Expanded(child: buildTodos(), flex: 1),
              VerticalDivider(),
              Expanded(child: buildAssignes(), flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Container buildAssignes() {
    return Container(
        constraints: BoxConstraints.expand(),
        // color: Colors.greenAccent,
        child: Column(
          children: [
            ButtonBar(children: [
              IconButton(
                icon: Icon(Icons.add),
                color: Colors.green,
                onPressed: _addPEOPLE,
              )
            ]),
            StreamBuilder<Set<Assignee>>(
                stream: SyncWrapper.instance.assignees.changeStream,
                initialData: {},
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return Center(child: Container(width: 100, height: 100, child: Text("Waiting on people")));

                  if (snap.hasData) {
                    final people = SyncWrapper.instance.assignees.allObjects();

                    return Container(
                        key: Key("${people.length}"),
                        height: 300,
                        width: 600,
                        child: ListView.builder(
                          itemCount: people.length,
                          itemBuilder: (ctx, index) {
                            final p = people[people.length - 1 - index];

                            if (firstName[p.id] == null) {
                              firstName[p.id] = TextEditingController(text: p.firstName);
                              firstName[p.id].addListener(() {
                                if (p.firstName != firstName[p.id].text) {
                                  p.firstName = firstName[p.id].text;
                                }
                              });
                            } else {
                              // copy time!! => :cry
                              firstName[p.id].value = firstName[p.id]
                                  .value
                                  .copyWith(text: p.firstName, selection: firstName[p.id].value.selection);
                            }

                            return ListTile(
                                key: Key(p.id),
                                leading: DragZoneAssignee(item: p),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(controller: firstName[p.id]),
                                      flex: 2,
                                    ),
                                    Expanded(
                                      child: Text(p.lastName),
                                      flex: 2,
                                    ),
                                    Expanded(
                                      child: Text(p.age.toString()),
                                      flex: 1,
                                    )
                                  ],
                                ),
                                subtitle: Container(width: 120, child: Text(p.todo?.title ?? 'no todo yet')),
                                trailing: Container(
                                  constraints: BoxConstraints.expand(width: 110),
                                  child: ButtonBar(
                                    alignment: MainAxisAlignment.start,
                                    layoutBehavior: ButtonBarLayoutBehavior.padded,
                                    mainAxisSize: MainAxisSize.max,
                                    buttonAlignedDropdown: connected,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.cancel),
                                        color: Colors.red,
                                        onPressed: () => p.tombstone = true,
                                      ),
                                    ],
                                  ),
                                )
                                // onTap: () => todo.status = !todo.status,
                                );
                          },
                        ));
                  }
                  return Text("no one to asign");
                }),
          ],
        ));
  }

  Container buildTodos() {
    return Container(
        constraints: BoxConstraints.expand(),
        // color: Colors.grey,
        child: Column(
          children: [
            ButtonBar(children: [
              IconButton(
                icon: Icon(Icons.add),
                color: Colors.green,
                onPressed: _addTODO,
              )
            ]),
            StreamBuilder<Set<Todo>>(
                stream: SyncWrapper.instance.todos.changeStream,
                initialData: {},
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return Center(child: Container(width: 100, height: 100, child: Text('Waiting on todos')));

                  if (snap.hasData) {
                    final todos = SyncWrapper.instance.todos.allObjects();

                    return Container(
                        key: Key("${todos.length}"),
                        height: 300,
                        width: 600,
                        child: ListView.builder(
                          itemCount: todos.length,
                          itemBuilder: (ctx, index) {
                            final todo = todos[todos.length - 1 - index];

                            if (todoTitles[todo.id] == null) {
                              todoTitles[todo.id] = TextEditingController(text: todo.title);
                              todoTitles[todo.id].addListener(() {
                                if (todo.title != todoTitles[todo.id].text) {
                                  todo.title = todoTitles[todo.id].text;
                                }
                              });
                            } else {
                              // copy time!! => :cry
                              todoTitles[todo.id].value = todoTitles[todo.id].value.copyWith(
                                    text: todo.title,
                                    selection: todoTitles[todo.id].value.selection,
                                  );
                            }

                            return ListTile(
                                key: Key(todo.id),
                                leading: DragZoneTodo(item: todo),
                                title: TextField(controller: todoTitles[todo.id]),
                                subtitle:
                                    Container(width: 120, child: Text(todo.assignee?.firstName ?? 'no assignee yet')),
                                trailing: Container(
                                  constraints: BoxConstraints.expand(width: 110),
                                  child: ButtonBar(
                                    alignment: MainAxisAlignment.start,
                                    layoutBehavior: ButtonBarLayoutBehavior.padded,
                                    mainAxisSize: MainAxisSize.max,
                                    buttonAlignedDropdown: connected,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.check_circle),
                                        color: todo.status ? Colors.green : Colors.grey,
                                        onPressed: () => todo.status = !todo.status,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.cancel),
                                        color: Colors.red,
                                        onPressed: () => todo.tombstone = true,
                                      ),
                                    ],
                                  ),
                                )
                                // onTap: () => todo.status = !todo.status,
                                );
                          },
                        ));
                  }
                  return Text("no Todos");
                }),
          ],
        ));
  }
}

class AssigneIconDrag extends StatelessWidget {
  const AssigneIconDrag({
    Key key,
    @required this.item,
  }) : super(key: key);

  final Assignee item;

  @override
  Widget build(BuildContext context) {
    return Draggable<Assignee>(
      data: item,
      child: Icon(Icons.people, color: Colors.green),
      feedback: Icon(Icons.people, color: Colors.pink),
      childWhenDragging: Icon(Icons.people),
    );
  }
}

class TodoIconDrag extends StatelessWidget {
  const TodoIconDrag({
    Key key,
    @required this.item,
  }) : super(key: key);

  final Todo item;

  @override
  Widget build(BuildContext context) {
    return Draggable<Todo>(
      data: item,
      child: Icon(Icons.work, color: Colors.green),
      feedback: Icon(Icons.work, color: Colors.pink),
      childWhenDragging: Icon(Icons.work),
    );
  }
}

class DragZoneAssignee extends StatelessWidget {
  const DragZoneAssignee({
    Key key,
    this.item,
  }) : super(key: key);
  final Assignee item;
  @override
  Widget build(BuildContext context) {
    return DragTarget<Todo>(
      builder: (BuildContext context, List<Todo> incoming, List rejected) {
        return Container(
          child: AssigneIconDrag(item: item),
          width: 50,
          height: 50,
          // margin: EdgeInsets.all(100.0),
          color: Colors.blueAccent,
          // decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
        );
      },
      onWillAccept: (data) {
        print(data);
        return true;
      },
      onAccept: (data) {
        print(data);
        item.todo = data;
      },
    );
  }
}

class DragZoneTodo extends StatelessWidget {
  const DragZoneTodo({
    Key key,
    this.item,
  }) : super(key: key);
  final Todo item;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Assignee>(
      builder: (BuildContext context, List<Assignee> incoming, List rejected) {
        return Container(
          child: TodoIconDrag(item: item),
          width: 50,
          height: 50,
          // margin: EdgeInsets.all(100.0),
          color: Colors.black,
          // decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
        );
      },
      onWillAccept: (data) {
        // print(data);
        return true;
      },
      onAccept: (data) {
        print(data);
        item.assignee = data;
      },
    );
  }
}
