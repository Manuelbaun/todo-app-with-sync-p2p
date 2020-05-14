import 'package:sync_layer/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';

import 'dao.dart';

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
      _syn = SyncLayerImpl(nodeID);
      _protocol = SyncLayerProtocol(_syn);

      // create first container by type
      _todos = _syn.registerObjectType<Todo>('todos', (c, id) => Todo(c, id: id));
      _assignees = _syn.registerObjectType<Assignee>('assignee', (c, id) => Assignee(c, id: id));
    } else {
      throw AssertionError('cant create this class twice?');
    }
  }

  SyncLayerProtocol _protocol;
  SyncLayerProtocol get protocol => _protocol;

  SyncLayerImpl _syn;
  SyncLayerImpl get syn => _syn;

  SyncableObjectContainer<Todo> get todos => _todos;
  SyncableObjectContainer<Todo> _todos;

  SyncableObjectContainer<Assignee> get assignees => _assignees;
  SyncableObjectContainer<Assignee> _assignees;
}