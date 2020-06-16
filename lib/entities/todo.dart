import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';

import 'assginee.dart';
import 'todo_type.dart';
import 'type_wrapper/sync_string.dart';

class Todo extends SyncableMap<int, Todo> {
  Todo(AccessProxy proxy, {String id, String title}) : super(proxy, id);

  SyncString get title => super[0];
  set title(SyncString v) => super[0] = v;

  bool get status => super[1];
  set status(bool v) => super[1] = v;

  // TodoType get group => super[3];
  // set group(TodoType v) {
  //   super[3] = v;

  //   v?.once(COMMON_EVENTS.DELETE, (data) {
  //     group = null;
  //   });
  // }

  Assignee get assignee => super[2];
  set assignee(Assignee v) {
    super[2] = v;
    v?.once(COMMON_EVENTS.DELETE, (data) {
      assignee = null;
    });
  }

  String toStringSimple() {
    if (tombstone) return 'Todo($id, deleted: $tombstone)';

    return 'Todo($id, $title : $lastUpdated)';
  }
}
