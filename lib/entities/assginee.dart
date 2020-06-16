import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';

import 'todo.dart';

class Assignee extends SyncableMap<int, Assignee> {
  Assignee(AccessProxy proxy, {String id, String title}) : super(proxy, id);

  String get firstName => super[0];
  set firstName(String v) => super[0] = v;
  String get lastName => super[1];
  set lastName(String v) => super[1] = v;
  int get age => super[2];
  set age(int v) => super[2] = v;

  Todo get todo => super[3] ?? null;
  set todo(Todo v) {
    super[3] = v;

    v?.once(COMMON_EVENTS.DELETE, (data) {
      todo = null;
    });
  }

  String toStringSimple() {
    if (tombstone) return 'Assignee($id, deleted: $tombstone)';
    return 'Assignee($id, $firstName, $lastName, $age : $lastUpdated)';
  }
}
