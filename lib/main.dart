import 'dart:io';
import 'dart:typed_data';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:sync_layer/encoding_extent/index.dart';

import 'package:todo_app/entities/index.dart';
import 'package:todo_app/sync/index.dart';
import 'package:todo_app/widgets/assignes_widgets.dart';

import 'package:todo_app/widgets/simple_text_editor_widget.dart';
import 'package:todo_app/widgets/todo_widgets.dart';

int localNodeName;
void main(List<String> arguments) {
  localNodeName = faker.randomGenerator.integer(0xffff);
  SyncWrapper.getInstance(localNodeName);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synclayer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Synclayer Demo TODO'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

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
    final text = SyncWrapper.instance.syncString.create();
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

  Uint8List bin;
  Uint8List zipped;
  Uint8List state;
  void save() async {
    final allAtoms = SyncWrapper.instance.syn.atomCache.allAtoms;
    final _state = SyncWrapper.instance.syn.getState().toMap();

    final allA = SyncWrapper.instance.assignees.allObjects();
    final allAS = allA.map((e) => e.toString()).toList();
    final allT = SyncWrapper.instance.todos.allObjects();
    final allTS = allT.map((e) => e.toString()).toList();
    final allS = SyncWrapper.instance.syncString.allObjects();
    final allSS = allS.map((e) => e.entriesUnfiltered).toList();

    final todos = msgpackEncode(allAS);
    final assign = msgpackEncode(allTS);
    final strr = msgpackEncode(allSS);
    state = msgpackEncode(_state);
    bin = msgpackEncode(allAtoms);

    final newPath = Directory.current.path + '\\' + 'serr';
    final dir = Directory(newPath)..createSync(recursive: true);
    final path = dir.path + '\\';
    final site = SyncWrapper.instance.syn.site;
    final file = File(path + '$site').openWrite();

    file.write(bin);
    file.write(state);
    file.write(todos);
    file.write(assign);
    file.write(strr);

    file.close();

    setState(() {
      bin = bin;
      zipped = zlib.encode(bin);
      state = state;
    });
  }

  Map<String, TextEditingController> firstName = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: connected ? Colors.green[400] : Colors.red[400],
        title: Row(
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
            ),
            VerticalDivider(),
            MaterialButton(
              onPressed: connect,
              color: Colors.white,
              child: Icon(Icons.call, color: Colors.green[400]),
            ),
            VerticalDivider(),
            MaterialButton(
              onPressed: disconnect,
              color: Colors.white,
              child: Icon(Icons.call_end, color: Colors.red[400]),
            ),
            MaterialButton(
              onPressed: save,
              color: Colors.white,
              child: Icon(Icons.save, color: Colors.blue[400]),
            ),
            VerticalDivider(),
            Text('Site ID: ${SyncWrapper.instance.syn.site}'),
            VerticalDivider(),
            Text('Size: ${bin?.length}'),
            VerticalDivider(),
            Text('zipped: ${zipped?.length}'),
            VerticalDivider(),
            Text('State: ${state?.length} ')
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: SizedBox.expand(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: buildTodos(), flex: 1),
                    VerticalDivider(),
                    Expanded(child: buildAssignes(), flex: 1),
                  ],
                ),
              ),
              Expanded(
                child: SimpleSyncableTextField(
                  id: '00',
                  initValue: '',
                  maxLines: 5,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAssignes() {
    return SizedBox.expand(
        child: Column(
      children: [
        ListTile(
          leading: Text('People'),
          trailing: IconButton(icon: Icon(Icons.add), onPressed: _addPEOPLE),
        ),
        Expanded(
          child: StreamBuilder<Set<Assignee>>(
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
        ),
      ],
    ));
  }

  Widget buildTodos() {
    return SizedBox.expand(
      child: Column(
        children: [
          ListTile(
            leading: Text('Todos'),
            trailing: IconButton(icon: Icon(Icons.add), onPressed: _addTODO),
          ),
          Expanded(
            child: StreamBuilder<Set<Todo>>(
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
          ),
        ],
      ),
    );
  }
}
