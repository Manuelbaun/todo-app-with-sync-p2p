import 'dart:io';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/sync/dao.dart';
import 'package:todo_app/sync/index.dart';
import 'package:todo_app/widgets/assignes_widgets.dart';

import 'package:todo_app/widgets/simple_text_editor_widget.dart';
import 'package:todo_app/widgets/todo_widgets.dart';

int localNodeName;
void main(List<String> arguments) {
  localNodeName = faker.randomGenerator.integer(10);
  SyncWrapper.getInstance(localNodeName);
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
  MyHomePage({Key key, this.title}) : super(key: key) {}

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
    final text = SyncWrapper.instance.syncArray.create();
    final title = faker.job.title();
    // text.transact((ref) {
    for (var i = 0; i < title.length; i++) {
      text.add(title[i]);
    }
    // });

    SyncWrapper.instance.todos.create()
      ..transact((ref) {
        ref.title = text;
        ref.status = false;
      });
  }

  void _addPEOPLE() {
    SyncWrapper.instance.assignees.create()
      ..transact((ref) {
        ref.firstName = faker.person.firstName();
        ref.lastName = faker.person.lastName();
        ref.age = faker.randomGenerator.integer(80, min: 20);
      });
  }

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
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(child: buildTodos(), flex: 1),
                    VerticalDivider(),
                    Expanded(child: buildAssignes(), flex: 1),
                  ],
                ),
              ),
              Expanded(
                  flex: 1,
                  child: SimpleSyncableTextField(
                    id: '00',
                    initValue: '',
                  ))
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
                onPressed: () => _addPEOPLE(),
              )
            ]),
            StreamBuilder<Set<Assignee>>(
                stream: SyncWrapper.instance.assignees.changeStream,
                initialData: {},
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return Center(
                        child: Container(
                            width: 100,
                            height: 100,
                            child: Text(
                              "Waiting on people",
                            )));

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
                                subtitle: Container(
                                    width: 120,
                                    child: p.todo != null
                                        ? StreamBuilder<List<dynamic>>(
                                            stream: p.todo.title.onChange,
                                            builder: (context, snapshot) {
                                              final str = p.todo.title.value ?? '... loading';

                                              return Text(str);
                                            })
                                        : Text('not assigned yet2')),
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
                                        onPressed: () => p.delete(),
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
                        // height: 300,
                        // width: 600,
                        constraints: BoxConstraints.tight(Size(600, 300)),
                        child: ListView.builder(
                          itemCount: todos.length,
                          itemBuilder: (ctx, index) {
                            final todo = todos[todos.length - 1 - index];

                            // if (todoTitles[todo.id] == null) {
                            //   todoTitles[todo.id] = TextEditingController(text: todo.title);
                            //   todoTitles[todo.id].addListener(() {
                            //     if (todo.title != todoTitles[todo.id].text) {
                            //       todo.title = todoTitles[todo.id].text;
                            //     }
                            //   });
                            // } else {
                            //   // copy time!! => :cry
                            //   todoTitles[todo.id].value = todoTitles[todo.id].value.copyWith(
                            //         text: todo.title,
                            //         selection: todoTitles[todo.id].value.selection,
                            //       );
                            // }

                            // TextField(controller: todoTitles[todo.id]),
                            return ListTile(
                                key: Key(todo.id),
                                leading: DragZoneTodo(item: todo),
                                title: SimpleSyncableTextField(id: '00', text: todo.title),
                                subtitle: Container(
                                    width: 120,
                                    child: Text(
                                      todo.assignee?.firstName ?? 'no assignee yet',
                                    )),
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
                                        onPressed: () => todo.delete(),
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
