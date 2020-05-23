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
    text.transact((self) {
      for (var i = 0; i < title.length; i++) {
        self.push(title[i]);
      }
    });

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
            Title(color: Colors.black, child: Text('People')),
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

                    return PeopleWidget(people: people, firstName: firstName, connected: connected);
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
            Title(color: Colors.black, child: Text('TODOs')),
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

                    return TodoWidget(todos: todos, connected: connected);
                  }
                  return Text("no Todos");
                }),
          ],
        ));
  }
}
