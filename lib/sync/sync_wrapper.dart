import 'package:sync_layer/index.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/sync_layer_impl.dart';
import 'package:todo_app/entities/index.dart';

class SyncWrapper {
  static SyncWrapper _instance;
  static SyncWrapper get instance => _instance;

  static SyncWrapper getInstance(int nodeId) {
    if (_instance == null) {
      _instance = SyncWrapper(nodeId);
    }
    return _instance;
  }

  final int nodeID;

  SyncWrapper(this.nodeID) {
    if (_instance == null) {
      _syn = SynchronizerImpl(nodeID);
      _protocol = SyncLayerProtocol(_syn);

      // create first container by type
      _todos = _syn.registerObjectType<Todo>('todos', (c, id) => Todo(c, id: id));
      _todoTypes = _syn.registerObjectType<TodoType>('todo_types', (c, id) => TodoType(c, id: id));
      _assignees = _syn.registerObjectType<Assignee>('assignee', (c, id) => Assignee(c, id: id));
      _syncString = syn.registerObjectType<SyncString>('syncarray', (c, id) => SyncString(c, id: id));

      // setupListener();
    } else {
      throw AssertionError('cant create this class twice?');
    }
  }

  void setupListener() {
    syncString.changeStream.listen((objs) {
      objs.forEach((o) => logger.info(o.entries.toString()));
    });

    todos.changeStream.listen((objs) {
      objs.forEach((o) => logger.info(o.toString()));
    });

    assignees.changeStream.listen((objs) => objs.forEach((o) => logger.info(o.toString())));
  }

  SyncLayerProtocol _protocol;
  SyncLayerProtocol get protocol => _protocol;

  SynchronizerImpl _syn;
  SynchronizerImpl get syn => _syn;

  SyncableObjectContainer<Todo> get todos => _todos;
  SyncableObjectContainer<Todo> _todos;

  SyncableObjectContainer<TodoType> get todoTypes => _todoTypes;
  SyncableObjectContainer<TodoType> _todoTypes;

  SyncableObjectContainer<Assignee> get assignees => _assignees;
  SyncableObjectContainer<Assignee> _assignees;

  SyncableObjectContainer<SyncString> get syncString => _syncString;
  SyncableObjectContainer<SyncString> _syncString;
}
