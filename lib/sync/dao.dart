import 'dart:async';

import 'package:sync_layer/sync/abstract/acess_proxy.dart';
import 'package:sync_layer/sync/index.dart';
import 'package:sync_layer/sync/syncable_causal_tree.dart';

class Todo extends SyncableObjectImpl<int, Todo> {
  Todo(AccessProxy proxy, {String id, String title}) : super(proxy, id);

  SyncString get title => super[0];
  set title(SyncString v) => super[0] = v;

  bool get status => super[1];
  set status(bool v) => super[1] = v;

  Assignee get assignee => super[2];
  set assignee(Assignee v) => super[2] = v;

  String toStringSimple() {
    if (tombstone) return 'Todo($id, deleted: $tombstone)';

    return 'Todo($id, $title : $lastUpdated)';
  }
}

class Assignee extends SyncableObjectImpl<int, Assignee> {
  Assignee(AccessProxy proxy, {String id, String title}) : super(proxy, id);

  String get firstName => super[0];
  set firstName(String v) => super[0] = v;

  String get lastName => super[1];
  set lastName(String v) => super[1] = v;

  int get age => super[2];
  set age(int v) => super[2] = v;

  Todo get todo => super[3];
  set todo(Todo v) => super[3] = v;

  String toStringSimple() {
    if (tombstone) return 'Assignee($id, deleted: $tombstone)';
    return 'Assignee($id, $firstName, $lastName, $age : $lastUpdated)';
  }
}

class SyncString extends SyncableCausalTree {
  SyncString(AccessProxy proxy, {String id}) : super(proxy, id);

  String get value => values.join('');
}

// class SyncArray extends SyncableCausalTree {
//   SyncText(AccessProxy proxy, {String id}) : super(proxy, id);
// }
